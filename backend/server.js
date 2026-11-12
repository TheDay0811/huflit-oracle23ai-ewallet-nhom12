const path = require('path');
const express = require('express');
const cors = require('cors');
const { oracledb, dbConfig, getConnection, closePool } = require('./db');

const app = express();
const PORT = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Helper sinh ma tham chieu Idempotency Key duy nhat
function genRef(prefix = 'TX') {
  return `${prefix}-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
}

// 1. Healthcheck ket noi Oracle 23ai
app.get('/api/health', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT BANNER_FULL AS VERSION, USER AS CURRENT_USER,
              SYS_CONTEXT('USERENV', 'CON_NAME') AS PDB_NAME
         FROM V$VERSION
        FETCH FIRST 1 ROWS ONLY`
    );
    res.json({
      ok: true,
      database: result.rows[0] || {},
      connectString: dbConfig.connectString
    });
  } catch (err) {
    res.status(503).json({
      ok: false,
      error: err.message,
      hint: 'Hay khoi dong Docker Oracle 23ai (docker compose up -d) va chay cac script SQL.'
    });
  } finally {
    if (conn) await conn.close();
  }
});

// 2. Tong quan Dashboard
app.get('/api/dashboard', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const [walletStats, txStats, errStats, recentTx, recentErrs] = await Promise.all([
      conn.execute(`
        SELECT COUNT(*) AS TONG_VI,
               SUM(CASE WHEN TRANG_THAI = 'HOAT_DONG' THEN 1 ELSE 0 END) AS VI_HOAT_DONG,
               SUM(CASE WHEN TRANG_THAI <> 'HOAT_DONG' THEN 1 ELSE 0 END) AS VI_BI_KHOA,
               NVL(SUM(SO_DU), 0) AS TONG_SO_DU_HE_THONG
          FROM VI_DIEN_TU
      `),
      conn.execute(`
        SELECT COUNT(*) AS TONG_GD,
               SUM(CASE WHEN NGAY_TAO >= CAST(TRUNC(SYSDATE) AS TIMESTAMP) THEN 1 ELSE 0 END) AS GD_HOM_NAY,
               NVL(SUM(CASE WHEN NGAY_TAO >= CAST(TRUNC(SYSDATE) AS TIMESTAMP) THEN SO_TIEN ELSE 0 END), 0) AS GIA_TRI_HOM_NAY
          FROM GIAO_DICH
         WHERE TRANG_THAI IN ('THANH_CONG', 'DA_HOAN_TIEN')
      `),
      conn.execute(`
        SELECT COUNT(*) AS TONG_LOI,
               SUM(CASE WHEN THOI_GIAN_LOI >= CAST(TRUNC(SYSDATE) AS TIMESTAMP) THEN 1 ELSE 0 END) AS LOI_HOM_NAY
          FROM NHAT_KY_LOI_GIAO_DICH
      `),
      conn.execute(`
        SELECT gd.MA_GD, gd.MA_THAM_CHIEU, gd.MA_VI_NGUON, gd.MA_VI_DICH,
               gd.MA_LOAI_GD, lgd.TEN_LOAI, gd.SO_TIEN, gd.PHI_GD, gd.TONG_TIEN,
               gd.NOI_DUNG, gd.TRANG_THAI, gd.NGUOI_THUC_HIEN,
               TO_CHAR(gd.NGAY_TAO, 'YYYY-MM-DD HH24:MI:SS') AS NGAY_TAO
          FROM GIAO_DICH gd
          JOIN LOAI_GIAO_DICH lgd ON gd.MA_LOAI_GD = lgd.MA_LOAI_GD
         ORDER BY gd.MA_GD DESC
         FETCH FIRST 20 ROWS ONLY
      `),
      conn.execute(`
        SELECT MA_LOG, MA_THAM_CHIEU, TEN_MODULE, MA_LOI_ORACLE,
               MA_LOI_NGHIEP_VU, THONG_DIEP_LOI, DU_LIEU_DAU_VAO,
               NGUOI_THUC_HIEN,
               TO_CHAR(THOI_GIAN_LOI, 'YYYY-MM-DD HH24:MI:SS') AS THOI_GIAN_LOI
          FROM NHAT_KY_LOI_GIAO_DICH
         ORDER BY MA_LOG DESC
         FETCH FIRST 15 ROWS ONLY
      `)
    ]);

    res.json({
      ok: true,
      walletStats: walletStats.rows[0],
      txStats: txStats.rows[0],
      errStats: errStats.rows[0],
      recentTx: recentTx.rows,
      recentErrs: recentErrs.rows
    });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 3. Danh sach vi (kem ham SQL-callable FN_TONG_CHI_TRONG_NGAY & FN_XEP_HANG_MUC_VI)
app.get('/api/wallets', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(`
      SELECT v.MA_VI, v.SO_TAI_KHOAN, v.LOAI_VI, v.MA_NV, v.HO_TEN, v.EMAIL,
             v.CHUC_VU, v.MA_PB, v.TEN_PB, v.SO_DU, v.SO_DU_KHA_DUNG,
             v.HAN_MUC_NGAY, v.TRANG_THAI,
             FN_TONG_CHI_TRONG_NGAY(v.MA_VI, SYSDATE) AS DA_CHI_HOM_NAY,
             FN_XEP_HANG_MUC_VI(v.MA_VI) AS HANG_MUC,
             TO_CHAR(v.NGAY_CAP_NHAT, 'YYYY-MM-DD HH24:MI:SS') AS NGAY_CAP_NHAT
        FROM VW_TONG_HOP_VI_NHAN_VIEN v
       ORDER BY v.LOAI_VI DESC, v.MA_VI ASC
    `);
    res.json({ ok: true, wallets: result.rows });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 4. Chi tiet so cai va lich su trang thai cua 1 vi
app.get('/api/wallets/:maVi/details', async (req, res) => {
  let conn;
  const { maVi } = req.params;
  try {
    conn = await getConnection();
    const [ledger, statusLog] = await Promise.all([
      conn.execute(
        `SELECT MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN,
                SO_DU_TRUOC, SO_DU_SAU, MO_TA,
                TO_CHAR(NGAY_GHI_SO, 'YYYY-MM-DD HH24:MI:SS') AS NGAY_GHI_SO
           FROM CHI_TIET_SO_CAI
          WHERE MA_VI = :maVi
          ORDER BY MA_BUT_TOAN DESC
          FETCH FIRST 30 ROWS ONLY`,
        { maVi }
      ),
      conn.execute(
        `SELECT MA_LOG_TT, MA_VI, TRANG_THAI_CU, TRANG_THAI_MOI, LY_DO, NGUOI_THAY_DOI,
                TO_CHAR(THOI_GIAN, 'YYYY-MM-DD HH24:MI:SS') AS THOI_GIAN
           FROM NHAT_KY_TRANG_THAI_VI
          WHERE MA_VI = :maVi
          ORDER BY MA_LOG_TT DESC
          FETCH FIRST 20 ROWS ONLY`,
        { maVi }
      )
    ]);
    res.json({ ok: true, ledger: ledger.rows, statusLog: statusLog.rows });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 5. Danh sach doi tac dich vu & loai giao dich
app.get('/api/catalog', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const [merchants, txTypes] = await Promise.all([
      conn.execute(`SELECT * FROM DOI_TAC_DICH_VU ORDER BY MA_DOI_TAC`),
      conn.execute(`SELECT * FROM LOAI_GIAO_DICH ORDER BY MA_LOAI_GD`)
    ]);
    res.json({ ok: true, merchants: merchants.rows, txTypes: txTypes.rows });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 6. Tinh phi giao dich qua Function FN_TINH_PHI_GIAO_DICH
app.get('/api/fee', async (req, res) => {
  let conn;
  const loaiGd = req.query.loaiGd || 'CHUYEN_NOI_BO';
  const soTien = Number(req.query.soTien || 0);
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT FN_TINH_PHI_GIAO_DICH(:loaiGd, :soTien) AS PHI_GD FROM DUAL`,
      { loaiGd, soTien }
    );
    res.json({ ok: true, fee: result.rows[0].PHI_GD });
  } catch (err) {
    res.status(400).json({ ok: false, error: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 7. Nap tien (PKG_QUAN_LY_VI.SP_NAP_TIEN)
app.post('/api/transactions/deposit', async (req, res) => {
  let conn;
  const { maVi, soTien, maThamChieu, noiDung, nguoiThucHien } = req.body;
  const ref = maThamChieu || genRef('NAP');
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_NAP_TIEN(
           p_ma_vi            => :maVi,
           p_so_tien          => :soTien,
           p_ma_tham_chieu    => :ref,
           p_noi_dung         => :noiDung,
           p_nguoi_thuc_hien  => :nguoiThucHien,
           p_ma_gd            => :maGd,
           p_ma_loi           => :maLoi,
           p_ma_loi_nghiep_vu => :maLoiNv,
           p_thong_bao        => :thongBao
         );
       END;`,
      {
        maVi,
        soTien: Number(soTien),
        ref,
        noiDung: noiDung || 'Nạp tiền từ giao diện Web',
        nguoiThucHien: nguoiThucHien || 'WEB_USER',
        maGd: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maThamChieu: ref,
      maGd: out.maGd,
      maLoiOracle: out.maLoi,
      maLoiNghiepVu: out.maLoiNv,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, maThamChieu: ref, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 8. Rut tien (PKG_QUAN_LY_VI.SP_RUT_TIEN)
app.post('/api/transactions/withdraw', async (req, res) => {
  let conn;
  const { maVi, soTien, maThamChieu, noiDung, nguoiThucHien } = req.body;
  const ref = maThamChieu || genRef('RUT');
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_RUT_TIEN(
           p_ma_vi            => :maVi,
           p_so_tien          => :soTien,
           p_ma_tham_chieu    => :ref,
           p_noi_dung         => :noiDung,
           p_nguoi_thuc_hien  => :nguoiThucHien,
           p_ma_gd            => :maGd,
           p_ma_loi           => :maLoi,
           p_ma_loi_nghiep_vu => :maLoiNv,
           p_thong_bao        => :thongBao
         );
       END;`,
      {
        maVi,
        soTien: Number(soTien),
        ref,
        noiDung: noiDung || 'Rút tiền về tài khoản ngân hàng',
        nguoiThucHien: nguoiThucHien || 'WEB_USER',
        maGd: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maThamChieu: ref,
      maGd: out.maGd,
      maLoiOracle: out.maLoi,
      maLoiNghiepVu: out.maLoiNv,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, maThamChieu: ref, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 9. Chuyen tien noi bo (PKG_QUAN_LY_VI.SP_CHUYEN_TIEN)
app.post('/api/transactions/transfer', async (req, res) => {
  let conn;
  const { maViNguon, maViDich, soTien, maThamChieu, noiDung, nguoiThucHien } = req.body;
  const ref = maThamChieu || genRef('TRF');
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
           p_ma_vi_nguon      => :maViNguon,
           p_ma_vi_dich       => :maViDich,
           p_so_tien          => :soTien,
           p_ma_tham_chieu    => :ref,
           p_noi_dung         => :noiDung,
           p_nguoi_thuc_hien  => :nguoiThucHien,
           p_ma_gd            => :maGd,
           p_ma_loi           => :maLoi,
           p_ma_loi_nghiep_vu => :maLoiNv,
           p_thong_bao        => :thongBao
         );
       END;`,
      {
        maViNguon,
        maViDich,
        soTien: Number(soTien),
        ref,
        noiDung: noiDung || 'Chuyển tiền nội bộ doanh nghiệp',
        nguoiThucHien: nguoiThucHien || 'WEB_USER',
        maGd: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maThamChieu: ref,
      maGd: out.maGd,
      maLoiOracle: out.maLoi,
      maLoiNghiepVu: out.maLoiNv,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, maThamChieu: ref, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 10. Thanh toan dich vu noi bo (PKG_QUAN_LY_VI.SP_THANH_TOAN_DICH_VU)
app.post('/api/transactions/pay-service', async (req, res) => {
  let conn;
  const { maViNguon, maDoiTac, soTien, maThamChieu, noiDung, nguoiThucHien } = req.body;
  const ref = maThamChieu || genRef('PAY');
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_THANH_TOAN_DICH_VU(
           p_ma_vi_nguon      => :maViNguon,
           p_ma_doi_tac       => :maDoiTac,
           p_so_tien          => :soTien,
           p_ma_tham_chieu    => :ref,
           p_noi_dung         => :noiDung,
           p_nguoi_thuc_hien  => :nguoiThucHien,
           p_ma_gd            => :maGd,
           p_ma_loi           => :maLoi,
           p_ma_loi_nghiep_vu => :maLoiNv,
           p_thong_bao        => :thongBao
         );
       END;`,
      {
        maViNguon,
        maDoiTac,
        soTien: Number(soTien),
        ref,
        noiDung: noiDung || 'Thanh toán dịch vụ nội bộ',
        nguoiThucHien: nguoiThucHien || 'WEB_USER',
        maGd: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maThamChieu: ref,
      maGd: out.maGd,
      maLoiOracle: out.maLoi,
      maLoiNghiepVu: out.maLoiNv,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, maThamChieu: ref, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 11. Hoan tien giao dich (PKG_QUAN_LY_VI.SP_HOAN_TIEN)
app.post('/api/transactions/refund', async (req, res) => {
  let conn;
  const { maGdGoc, maThamChieu, lyDo, nguoiThucHien } = req.body;
  const ref = maThamChieu || genRef('RFN');
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_HOAN_TIEN(
           p_ma_gd_goc        => :maGdGoc,
           p_ma_tham_chieu    => :ref,
           p_ly_do            => :lyDo,
           p_nguoi_thuc_hien  => :nguoiThucHien,
           p_ma_gd_hoan       => :maGdHoan,
           p_ma_loi           => :maLoi,
           p_ma_loi_nghiep_vu => :maLoiNv,
           p_thong_bao        => :thongBao
         );
       END;`,
      {
        maGdGoc: Number(maGdGoc),
        ref,
        lyDo: lyDo || 'Hoàn tiền theo yêu cầu trên giao diện Web',
        nguoiThucHien: nguoiThucHien || 'WEB_ADMIN',
        maGdHoan: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maThamChieu: ref,
      maGd: out.maGdHoan,
      maLoiOracle: out.maLoi,
      maLoiNghiepVu: out.maLoiNv,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, maThamChieu: ref, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 12. Khoa / Mo khoa vi (Kich hoat Trigger TRG_NHAT_KY_TRANG_THAI_VI)
app.post('/api/wallets/:maVi/status', async (req, res) => {
  let conn;
  const { maVi } = req.params;
  const { trangThaiMoi, lyDo, nguoiThucHien } = req.body;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_KHOA_MO_VI(
           p_ma_vi           => :maVi,
           p_trang_thai_moi  => :trangThaiMoi,
           p_ly_do           => :lyDo,
           p_nguoi_thuc_hien => :nguoiThucHien,
           p_ma_loi          => :maLoi,
           p_thong_bao       => :thongBao
         );
       END;`,
      {
        maVi,
        trangThaiMoi,
        lyDo: lyDo || 'Thay đổi trạng thái từ Web Console',
        nguoiThucHien: nguoiThucHien || 'WEB_ADMIN',
        maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
      }
    );

    const out = result.outBinds;
    const isSuccess = out.maLoi === 0;
    res.status(isSuccess ? 200 : 400).json({
      ok: isSuccess,
      maLoiOracle: out.maLoi,
      thongBao: out.thongBao
    });
  } catch (err) {
    res.status(500).json({ ok: false, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 13. Chay doi soat hang loat bang Explicit Cursor (PKG_QUAN_LY_VI.SP_DOI_SOAT_HANG_LOAT)
app.post('/api/reconcile', async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `BEGIN
         PKG_QUAN_LY_VI.SP_DOI_SOAT_HANG_LOAT(
           p_tong_vi_kiem_tra => :tongVi,
           p_so_vi_lech       => :viLech,
           p_chi_tiet_ket_qua => :chiTiet
         );
       END;`,
      {
        tongVi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        viLech: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        chiTiet: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 2000 }
      }
    );
    res.json({
      ok: true,
      tongViKiemTra: result.outBinds.tongVi,
      soViLech: result.outBinds.viLech,
      thongBao: result.outBinds.chiTiet
    });
  } catch (err) {
    res.status(500).json({ ok: false, thongBao: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// 14. Kiem thu dong thoi (2 giao dich cung gui song song voi 1 Idempotency Key)
app.post('/api/test-concurrent-duplicate', async (req, res) => {
  const { maViNguon, maViDich, soTien } = req.body;
  const sharedRef = genRef('RACE');

  const sendOne = async (tag) => {
    let conn;
    try {
      conn = await getConnection();
      const result = await conn.execute(
        `BEGIN
           PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
             p_ma_vi_nguon      => :maViNguon,
             p_ma_vi_dich       => :maViDich,
             p_so_tien          => :soTien,
             p_ma_tham_chieu    => :ref,
             p_noi_dung         => :noiDung,
             p_nguoi_thuc_hien  => :tag,
             p_ma_gd            => :maGd,
             p_ma_loi           => :maLoi,
             p_ma_loi_nghiep_vu => :maLoiNv,
             p_thong_bao        => :thongBao
           );
         END;`,
        {
          maViNguon: maViNguon || 'VI001',
          maViDich: maViDich || 'VI002',
          soTien: Number(soTien || 50000),
          ref: sharedRef,
          noiDung: `Kiểm thử race-condition (${tag})`,
          tag,
          maGd: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          maLoi: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
          maLoiNv: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 60 },
          thongBao: { dir: oracledb.BIND_OUT, type: oracledb.STRING, maxSize: 1000 }
        }
      );
      return { tag, ...result.outBinds };
    } finally {
      if (conn) await conn.close();
    }
  };

  try {
    const [r1, r2] = await Promise.all([sendOne('THREAD_A'), sendOne('THREAD_B')]);
    res.json({ ok: true, sharedRef, results: [r1, r2] });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

// Fallback route cho SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const server = app.listen(PORT, () => {
  console.log(`[EWALLET-API] Server dang chay tai http://localhost:${PORT}`);
  console.log(`[EWALLET-API] Oracle target: ${dbConfig.connectString} (User: ${dbConfig.user})`);
});

process.on('SIGINT', async () => {
  console.log('\n[EWALLET-API] Dang dong ket noi Oracle...');
  await closePool().catch(() => {});
  server.close(() => process.exit(0));
});
