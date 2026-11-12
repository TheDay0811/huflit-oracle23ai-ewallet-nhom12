-- ============================================================================
-- 09_test_scenarios.sql
-- Bo 9 kich ban kiem thu nghiep vu va ngoai le (Happy Path + Edge/Exception + Compound Trigger)
-- Ban SQL*Plus/Docker (ban danh rieng cho DBeaver Alt+X nam tai sql_dbeaver/)
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

-- Kiem tra ham SQL-callable va Oracle 23ai native BOOLEAN trong SQL
SELECT MA_VI,
       SO_DU,
       TRANG_THAI,
       FN_TINH_PHI_GIAO_DICH('RUT_TIEN', 2000000) AS PHI_RUT_2TR,
       FN_TONG_CHI_TRONG_NGAY(MA_VI, SYSDATE)     AS DA_CHI_HOM_NAY,
       FN_XEP_HANG_MUC_VI(MA_VI)                  AS HANG_MUC_VI,
       FN_KIEM_TRA_VI_HOAT_DONG(MA_VI)            AS DANG_HOAT_DONG_BOOL
  FROM VI_DIEN_TU
 WHERE MA_VI IN ('VI001', 'VI006', 'VI007')
 ORDER BY MA_VI;

-- Chay bo 8 kich ban kiem thu PL/SQL (Exception Handling + Rollback + Autonomous Log)
DECLARE
    v_ma_gd      NUMBER;
    v_ma_gd_hoan NUMBER;
    v_ma_loi     NUMBER;
    v_err_code  VARCHAR2(50);
    v_msg       NVARCHAR2(500);
    v_tong_vi   NUMBER;
    v_vi_lech   NUMBER;
    v_kq_ds     NVARCHAR2(2000);
    v_ref_dup   VARCHAR2(80) := 'TC04-DUP-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_ref_ok    VARCHAR2(80) := 'TC02-OK-'  || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_ref_nap   VARCHAR2(80) := 'TC01-NAP-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_ref_hoan  VARCHAR2(80) := 'TC07-RFN-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== BAT DAU CHAY 9 KICH BAN KIEM THU ===');

    -- TC01: Nap tien hop le vao VI001
    PKG_QUAN_LY_VI.SP_NAP_TIEN(
        p_ma_vi => 'VI001', p_so_tien => 500000, p_ma_tham_chieu => v_ref_nap,
        p_noi_dung => N'TC01: Nạp tiền kiểm thử', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC01] MaLoi=' || v_ma_loi || ' | ' || v_msg);

    -- TC02: Chuyen tien hop le tu VI001 sang VI002
    PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
        p_ma_vi_nguon => 'VI001', p_ma_vi_dich => 'VI002', p_so_tien => 200000,
        p_ma_tham_chieu => v_ref_ok, p_noi_dung => N'TC02: Chuyển tiền hợp lệ',
        p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC02] MaLoi=' || v_ma_loi || ' | GD=' || v_ma_gd || ' | ' || v_msg);

    -- TC03: Ngoai le so du khong du (-20001) tren VI007 (vi chi co 50.000d)
    PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
        p_ma_vi_nguon => 'VI007', p_ma_vi_dich => 'VI002', p_so_tien => 5000000,
        p_ma_tham_chieu => 'TC03-LOWBAL-' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3'),
        p_noi_dung => N'TC03: Test số dư không đủ', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC03] MaLoi=' || v_ma_loi || ' (' || v_err_code || ') | ' || v_msg);

    -- TC04: Ngoai le giao dich trung lap (-20002) bang Idempotency Key
    PKG_QUAN_LY_VI.SP_NAP_TIEN(
        p_ma_vi => 'VI002', p_so_tien => 100000, p_ma_tham_chieu => v_ref_dup,
        p_noi_dung => N'TC04: Giao dịch lần 1', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    PKG_QUAN_LY_VI.SP_NAP_TIEN(
        p_ma_vi => 'VI002', p_so_tien => 100000, p_ma_tham_chieu => v_ref_dup,
        p_noi_dung => N'TC04: Giao dịch trùng lặp lần 2', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC04] MaLoi=' || v_ma_loi || ' (' || v_err_code || ') | ' || v_msg);

    -- TC05: Ngoai le vi bi khoa (-20003) tren VI006 (dang TAM_KHOA)
    PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
        p_ma_vi_nguon => 'VI006', p_ma_vi_dich => 'VI001', p_so_tien => 100000,
        p_ma_tham_chieu => 'TC05-LOCKED-' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3'),
        p_noi_dung => N'TC05: Test ví nguồn bị khoá', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC05] MaLoi=' || v_ma_loi || ' (' || v_err_code || ') | ' || v_msg);

    -- TC06: Ngoai le vuot han muc ngay (-20005) tren VI005 (han muc 20.000.000d/ngay)
    PKG_QUAN_LY_VI.SP_CHUYEN_TIEN(
        p_ma_vi_nguon => 'VI005', p_ma_vi_dich => 'VI001', p_so_tien => 25000000,
        p_ma_tham_chieu => 'TC06-LIMIT-' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3'),
        p_noi_dung => N'TC06: Test vượt hạn mức ngày', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd => v_ma_gd, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC06] MaLoi=' || v_ma_loi || ' (' || v_err_code || ') | ' || v_msg);

    -- TC07: Hoan tien giao dich TC02 va thu hoan lai lan 2 (bi chan boi -20009)
    SELECT MA_GD INTO v_ma_gd FROM GIAO_DICH WHERE MA_THAM_CHIEU = v_ref_ok;
    PKG_QUAN_LY_VI.SP_HOAN_TIEN(
        p_ma_gd_goc => v_ma_gd, p_ma_tham_chieu => v_ref_hoan,
        p_ly_do => N'TC07: Hoàn tiền giao dịch kiểm thử', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd_hoan => v_ma_gd_hoan, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC07a Hoan tien] MaLoi=' || v_ma_loi || ' | GD_Hoan=' || v_ma_gd_hoan || ' | ' || v_msg);

    PKG_QUAN_LY_VI.SP_HOAN_TIEN(
        p_ma_gd_goc => v_ma_gd, p_ma_tham_chieu => v_ref_hoan || '-2',
        p_ly_do => N'TC07b: Thử hoàn tiền lần 2 (ngoại lệ)', p_nguoi_thuc_hien => 'TEST_RUNNER',
        p_ma_gd_hoan => v_ma_gd_hoan, p_ma_loi => v_ma_loi, p_ma_loi_nghiep_vu => v_err_code, p_thong_bao => v_msg
    );
    DBMS_OUTPUT.PUT_LINE('[TC07b Hoan lai] MaLoi=' || v_ma_loi || ' (' || v_err_code || ') | ' || v_msg);

    -- TC08: Doi soat hang loat bang Explicit Cursor
    PKG_QUAN_LY_VI.SP_DOI_SOAT_HANG_LOAT(v_tong_vi, v_vi_lech, v_kq_ds);
    DBMS_OUTPUT.PUT_LINE('[TC08 Doi soat] TongVi=' || v_tong_vi || ' | Lech=' || v_vi_lech || ' | ' || v_kq_ds);

    -- TC09: Kiem thu Compound Trigger TRG_KIEM_SOAT_GD_BATTUONG (khong gap ORA-04091 Mutating Table)
    BEGIN
        INSERT INTO GIAO_DICH (
            MA_GD, MA_THAM_CHIEU, MA_VI_NGUON, MA_VI_DICH, MA_LOAI_GD,
            SO_TIEN, PHI_GD, TONG_TIEN, NOI_DUNG, TRANG_THAI, NGUOI_THUC_HIEN
        ) VALUES (
            SEQ_GIAO_DICH.NEXTVAL,
            'TC09-CMP-' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3'),
            'VI005', 'VI001', 'CHUYEN_NOI_BO',
            25000000, 0, 25000000,
            N'TC09: Test Compound Trigger trực tiếp trên bảng GIAO_DICH',
            'THANH_CONG', 'TEST_RUNNER'
        );
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            v_ma_loi := SQLCODE;
            v_msg    := SQLERRM;
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('[TC09 Compound Trigger] MaLoi=' || v_ma_loi || ' | ' || v_msg);
    END;
END;
/

-- Kiem tra ket qua nhat ky loi duoc ghi lai bang PRAGMA AUTONOMOUS_TRANSACTION
SELECT MA_LOG, TEN_MODULE, MA_LOI_ORACLE, MA_LOI_NGHIEP_VU, THONG_DIEP_LOI, THOI_GIAN_LOI
  FROM NHAT_KY_LOI_GIAO_DICH
 ORDER BY MA_LOG DESC
 FETCH FIRST 10 ROWS ONLY;
