-- ============================================================================
-- 04_seed_data.sql
-- Du lieu mau thuc te + 15.000 giao dich lich su can bang so cai kep
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

-- 1. Phong ban
INSERT INTO PHONG_BAN (MA_PB, TEN_PB, HAN_MUC_CHI_THANG) VALUES ('PB_CNTT', N'Phòng Công nghệ thông tin', 800000000);
INSERT INTO PHONG_BAN (MA_PB, TEN_PB, HAN_MUC_CHI_THANG) VALUES ('PB_KTTC', N'Phòng Kế toán - Tài chính', 600000000);
INSERT INTO PHONG_BAN (MA_PB, TEN_PB, HAN_MUC_CHI_THANG) VALUES ('PB_HCNS', N'Phòng Hành chính - Nhân sự', 500000000);
INSERT INTO PHONG_BAN (MA_PB, TEN_PB, HAN_MUC_CHI_THANG) VALUES ('PB_KD',   N'Phòng Kinh doanh', 700000000);
INSERT INTO PHONG_BAN (MA_PB, TEN_PB, HAN_MUC_CHI_THANG) VALUES ('PB_DVNB', N'Ban Quản lý Dịch vụ nội bộ', 400000000);

-- 2. Nhan vien (Bao gom cac thanh vien nhom va nhan su nghiep vu mau)
INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV001', N'Nguyễn Quốc Huy', 'huy.nq@corp-ewallet.vn', '0902637150', N'Trưởng nhóm Kỹ thuật', 'PB_CNTT');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV002', N'Phạm Thành Đức', 'duc.pt@corp-ewallet.vn', '0903112233', N'Kỹ sư Cơ sở dữ liệu', 'PB_CNTT');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV003', N'Nguyễn Thế Vinh', 'vinh.nt@corp-ewallet.vn', '0904223344', N'Chuyên viên Phát triển API', 'PB_CNTT');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV004', N'Trần Minh Anh', 'anh.tm@corp-ewallet.vn', '0905334455', N'Kế toán trưởng', 'PB_KTTC');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV005', N'Lê Hoàng Phúc', 'phuc.lh@corp-ewallet.vn', '0906445566', N'Chuyên viên Nhân sự', 'PB_HCNS');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV006', N'Võ Thị Thu Hà', 'ha.vtt@corp-ewallet.vn', '0907556677', N'Chuyên viên Kinh doanh (Ví tạm khoá)', 'PB_KD');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV007', N'Đặng Quốc Bảo', 'bao.dq@corp-ewallet.vn', '0908667788', N'Thực tập sinh (Ví số dư thấp)', 'PB_KD');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV008', N'Bùi Ngọc Lan', 'lan.bn@corp-ewallet.vn', '0909778899', N'Quản lý Căn tin nội bộ', 'PB_DVNB');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV009', N'Phan Văn Hùng', 'hung.pv@corp-ewallet.vn', '0911889900', N'Quản lý Bãi xe thông minh', 'PB_DVNB');

INSERT INTO NHAN_VIEN (MA_NV, HO_TEN, EMAIL, SO_DIEN_THOAI, CHUC_VU, MA_PB)
VALUES ('NV010', N'Hoàng Mỹ Linh', 'linh.hm@corp-ewallet.vn', '0912990011', N'Quản lý Trung tâm In ấn', 'PB_DVNB');

-- 3. Loai giao dich va bieu phi
INSERT INTO LOAI_GIAO_DICH (MA_LOAI_GD, TEN_LOAI, PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA, CO_TINH_HAN_MUC, MO_TA)
VALUES ('NAP_TIEN', N'Nạp tiền vào ví nội bộ', 0, 0, 0, 0, N'Nạp tiền từ ngân hàng liên kết hoặc quỹ lương doanh nghiệp');

INSERT INTO LOAI_GIAO_DICH (MA_LOAI_GD, TEN_LOAI, PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA, CO_TINH_HAN_MUC, MO_TA)
VALUES ('RUT_TIEN', N'Rút tiền về tài khoản ngân hàng', 1000, 0.0010, 20000, 1, N'Phí cố định 1.000đ cộng 0,1% giá trị rút (tối đa 20.000đ)');

INSERT INTO LOAI_GIAO_DICH (MA_LOAI_GD, TEN_LOAI, PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA, CO_TINH_HAN_MUC, MO_TA)
VALUES ('CHUYEN_NOI_BO', N'Chuyển tiền giữa các ví nội bộ', 0, 0, 0, 1, N'Miễn phí chuyển tiền tức thời giữa nhân viên trong doanh nghiệp');

INSERT INTO LOAI_GIAO_DICH (MA_LOAI_GD, TEN_LOAI, PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA, CO_TINH_HAN_MUC, MO_TA)
VALUES ('THANH_TOAN_DV', N'Thanh toán dịch vụ nội bộ', 0, 0, 0, 1, N'Thanh toán tại căn tin, bãi giữ xe, trung tâm in ấn nội bộ');

INSERT INTO LOAI_GIAO_DICH (MA_LOAI_GD, TEN_LOAI, PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA, CO_TINH_HAN_MUC, MO_TA)
VALUES ('HOAN_TIEN', N'Hoàn tiền giao dịch nội bộ', 0, 0, 0, 0, N'Hoàn trả tiền cho giao dịch chuyển khoản hoặc thanh toán dịch vụ');

-- 4. Vi dien tu (Khoi tao so du ban dau = 0, se nap von bang giao dich khoi tao ben duoi)
INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI001', 'EW-2411-3268', 'NV001', 'NHAN_VIEN', 0, 0, 50000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI002', 'EW-2411-3249', 'NV002', 'NHAN_VIEN', 0, 0, 30000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI003', 'EW-2414-1906', 'NV003', 'NHAN_VIEN', 0, 0, 30000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI004', 'EW-1000-0004', 'NV004', 'NHAN_VIEN', 0, 0, 100000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI005', 'EW-1000-0005', 'NV005', 'NHAN_VIEN', 0, 0, 20000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI006', 'EW-1000-0006', 'NV006', 'NHAN_VIEN', 0, 0, 20000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI007', 'EW-1000-0007', 'NV007', 'NHAN_VIEN', 0, 0, 5000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI_DT_CANTIN', 'EW-MER-CANTIN', 'NV008', 'DOI_TAC', 0, 0, 500000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI_DT_BAIXE',  'EW-MER-BAIXE',  'NV009', 'DOI_TAC', 0, 0, 500000000, 'HOAT_DONG');

INSERT INTO VI_DIEN_TU (MA_VI, SO_TAI_KHOAN, MA_NV, LOAI_VI, SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI)
VALUES ('VI_DT_INAN',   'EW-MER-INAN',   'NV010', 'DOI_TAC', 0, 0, 500000000, 'HOAT_DONG');

-- 5. Doi tac dich vu noi bo
INSERT INTO DOI_TAC_DICH_VU (MA_DOI_TAC, TEN_DOI_TAC, LOAI_DICH_VU, MA_VI_NHAN)
VALUES ('DT_CANTIN', N'Căn tin Trụ sở chính', 'CAN_TIN', 'VI_DT_CANTIN');

INSERT INTO DOI_TAC_DICH_VU (MA_DOI_TAC, TEN_DOI_TAC, LOAI_DICH_VU, MA_VI_NHAN)
VALUES ('DT_BAIXE', N'Bãi giữ xe thông minh tầng hầm', 'BAI_XE', 'VI_DT_BAIXE');

INSERT INTO DOI_TAC_DICH_VU (MA_DOI_TAC, TEN_DOI_TAC, LOAI_DICH_VU, MA_VI_NHAN)
VALUES ('DT_INAN', N'Trung tâm In ấn - Văn phòng phẩm', 'IN_AN', 'VI_DT_INAN');

COMMIT;

-- 6. Sinh du lieu lich su 15.000 giao dich + so cai kep can bang tuyet doi
DECLARE
    TYPE t_str_arr IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE t_num_map IS TABLE OF NUMBER(18, 2) INDEX BY VARCHAR2(20);
    TYPE t_gd_tab  IS TABLE OF GIAO_DICH%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE t_sc_tab  IS TABLE OF CHI_TIET_SO_CAI%ROWTYPE INDEX BY PLS_INTEGER;

    v_wallets     t_str_arr;
    v_merchants   t_str_arr;
    v_bal         t_num_map;
    v_gd_list     t_gd_tab;
    v_sc_list     t_sc_tab;

    v_gd_idx      PLS_INTEGER := 0;
    v_sc_idx      PLS_INTEGER := 0;
    v_ma_gd       NUMBER(18);
    v_src         VARCHAR2(20);
    v_dst         VARCHAR2(20);
    v_amt         NUMBER(18, 2);
    v_ts          TIMESTAMP;
    v_loai        VARCHAR2(30);
    v_src_idx     PLS_INTEGER;
    v_dst_idx     PLS_INTEGER;
    v_init_amt    NUMBER(18, 2);

    PROCEDURE add_gd(
        p_ma_gd    NUMBER,
        p_ref      VARCHAR2,
        p_src      VARCHAR2,
        p_dst      VARCHAR2,
        p_loai     VARCHAR2,
        p_amt      NUMBER,
        p_desc     NVARCHAR2,
        p_ts       TIMESTAMP
    ) IS
    BEGIN
        v_gd_idx := v_gd_idx + 1;
        v_gd_list(v_gd_idx).MA_GD           := p_ma_gd;
        v_gd_list(v_gd_idx).MA_THAM_CHIEU   := p_ref;
        v_gd_list(v_gd_idx).MA_VI_NGUON     := p_src;
        v_gd_list(v_gd_idx).MA_VI_DICH      := p_dst;
        v_gd_list(v_gd_idx).MA_LOAI_GD      := p_loai;
        v_gd_list(v_gd_idx).MA_GD_GOC       := NULL;
        v_gd_list(v_gd_idx).SO_TIEN         := p_amt;
        v_gd_list(v_gd_idx).PHI_GD          := 0;
        v_gd_list(v_gd_idx).TONG_TIEN       := p_amt;
        v_gd_list(v_gd_idx).NOI_DUNG        := p_desc;
        v_gd_list(v_gd_idx).TRANG_THAI      := 'THANH_CONG';
        v_gd_list(v_gd_idx).NGUOI_THUC_HIEN := 'SEED_LOADER';
        v_gd_list(v_gd_idx).NGAY_TAO        := p_ts;
        v_gd_list(v_gd_idx).NGAY_HOAN_TAT   := p_ts;
    END;

    PROCEDURE add_ledger(
        p_ma_gd   NUMBER,
        p_vi      VARCHAR2,
        p_loai_bt VARCHAR2,
        p_amt     NUMBER,
        p_before  NUMBER,
        p_after   NUMBER,
        p_desc    NVARCHAR2,
        p_ts      TIMESTAMP
    ) IS
    BEGIN
        v_sc_idx := v_sc_idx + 1;
        v_sc_list(v_sc_idx).MA_BUT_TOAN   := SEQ_SO_CAI.NEXTVAL;
        v_sc_list(v_sc_idx).MA_GD         := p_ma_gd;
        v_sc_list(v_sc_idx).MA_VI         := p_vi;
        v_sc_list(v_sc_idx).LOAI_BUT_TOAN := p_loai_bt;
        v_sc_list(v_sc_idx).SO_TIEN       := p_amt;
        v_sc_list(v_sc_idx).SO_DU_TRUOC   := p_before;
        v_sc_list(v_sc_idx).SO_DU_SAU     := p_after;
        v_sc_list(v_sc_idx).MO_TA         := p_desc;
        v_sc_list(v_sc_idx).NGAY_GHI_SO   := p_ts;
    END;
BEGIN
    v_wallets(1) := 'VI001';
    v_wallets(2) := 'VI002';
    v_wallets(3) := 'VI003';
    v_wallets(4) := 'VI004';
    v_wallets(5) := 'VI005';
    v_wallets(6) := 'VI006';
    v_wallets(7) := 'VI007';

    v_merchants(1) := 'VI_DT_CANTIN';
    v_merchants(2) := 'VI_DT_BAIXE';
    v_merchants(3) := 'VI_DT_INAN';

    FOR i IN 1 .. 7 LOOP
        v_bal(v_wallets(i)) := 0;
    END LOOP;
    FOR i IN 1 .. 3 LOOP
        v_bal(v_merchants(i)) := 0;
    END LOOP;

    -- Nap tien khoi tao cho cac vi (185 ngay truoc)
    FOR i IN 1 .. 7 LOOP
        IF v_wallets(i) = 'VI007' THEN
            v_init_amt := 50000;
        ELSIF v_wallets(i) = 'VI004' THEN
            v_init_amt := 80000000;
        ELSE
            v_init_amt := 25000000;
        END IF;

        v_ma_gd := SEQ_GIAO_DICH.NEXTVAL;
        v_ts    := SYSTIMESTAMP - NUMTODSINTERVAL(185, 'DAY');

        add_gd(v_ma_gd, 'SEED-INIT-' || v_wallets(i), NULL, v_wallets(i), 'NAP_TIEN',
               v_init_amt, N'Cấp hạn mức ví điện tử nội bộ kỳ đầu', v_ts);
        add_ledger(v_ma_gd, v_wallets(i), 'GHI_CO', v_init_amt, 0, v_init_amt, N'Nạp tiền khởi tạo ví', v_ts);
        v_bal(v_wallets(i)) := v_init_amt;
    END LOOP;

    -- Sinh 15.000 giao dich lich su trong 1..180 ngay qua
    FOR k IN 1 .. 15000 LOOP
        v_src_idx := MOD(k, 5) + 1;
        v_src     := v_wallets(v_src_idx);
        v_ts      := SYSTIMESTAMP - NUMTODSINTERVAL(1 + MOD(k * 7, 179) + (MOD(k, 1440) / 1440), 'DAY');

        IF v_bal(v_src) < 1000000 THEN
            v_amt   := 10000000;
            v_ma_gd := SEQ_GIAO_DICH.NEXTVAL;
            add_gd(v_ma_gd, 'SEED-TOPUP-' || k, NULL, v_src, 'NAP_TIEN',
                   v_amt, N'Nạp tiền định kỳ hàng tháng', v_ts);
            add_ledger(v_ma_gd, v_src, 'GHI_CO', v_amt, v_bal(v_src), v_bal(v_src) + v_amt, N'Nạp tiền định kỳ', v_ts);
            v_bal(v_src) := v_bal(v_src) + v_amt;
        END IF;

        IF MOD(k, 4) = 0 THEN
            v_dst_idx := MOD(k + 1, 5) + 1;
            IF v_dst_idx = v_src_idx THEN
                v_dst_idx := MOD(v_src_idx, 5) + 1;
            END IF;
            v_dst  := v_wallets(v_dst_idx);
            v_loai := 'CHUYEN_NOI_BO';
            v_amt  := (MOD(k, 20) + 1) * 25000;
        ELSE
            v_dst  := v_merchants(MOD(k, 3) + 1);
            v_loai := 'THANH_TOAN_DV';
            v_amt  := (MOD(k, 10) + 1) * 15000;
        END IF;

        v_ma_gd := SEQ_GIAO_DICH.NEXTVAL;
        add_gd(
            v_ma_gd,
            'SEED-TX-' || LPAD(TO_CHAR(k), 6, '0'),
            v_src,
            v_dst,
            v_loai,
            v_amt,
            CASE v_loai
                WHEN 'CHUYEN_NOI_BO' THEN N'Chuyển tiền nội bộ #' || k
                ELSE N'Thanh toán dịch vụ nội bộ #' || k
            END,
            v_ts
        );

        add_ledger(v_ma_gd, v_src, 'GHI_NO', v_amt, v_bal(v_src), v_bal(v_src) - v_amt, N'Ghi nợ giao dịch #' || k, v_ts);
        v_bal(v_src) := v_bal(v_src) - v_amt;

        add_ledger(v_ma_gd, v_dst, 'GHI_CO', v_amt, v_bal(v_dst), v_bal(v_dst) + v_amt, N'Ghi có giao dịch #' || k, v_ts);
        v_bal(v_dst) := v_bal(v_dst) + v_amt;
    END LOOP;

    -- Dam bao VI005 co so du >= 35.000.000d (lon hon han muc ngay 20.000.000d) de kiem thu chuan xac ngoai le -20005
    IF v_bal('VI005') < 35000000 THEN
        v_amt   := 35000000;
        v_ts    := SYSTIMESTAMP - NUMTODSINTERVAL(1, 'DAY');
        v_ma_gd := SEQ_GIAO_DICH.NEXTVAL;
        add_gd(v_ma_gd, 'SEED-TOPUP-VI005-FINAL', NULL, 'VI005', 'NAP_TIEN',
               v_amt, N'Bổ sung hạn mức khả dụng kỳ mới cho VI005', v_ts);
        add_ledger(v_ma_gd, 'VI005', 'GHI_CO', v_amt, v_bal('VI005'), v_bal('VI005') + v_amt, N'Bổ sung vốn VI005', v_ts);
        v_bal('VI005') := v_bal('VI005') + v_amt;
    END IF;

    -- Bulk insert toan bo bang ghi (%ROWTYPE tranh loi PLS-00436)
    FORALL idx IN 1 .. v_gd_list.COUNT
        INSERT INTO GIAO_DICH VALUES v_gd_list(idx);

    FORALL idx IN 1 .. v_sc_list.COUNT
        INSERT INTO CHI_TIET_SO_CAI VALUES v_sc_list(idx);

    -- Dong bo so du cuoi cung vao VI_DIEN_TU
    FOR i IN 1 .. 7 LOOP
        UPDATE VI_DIEN_TU
           SET SO_DU          = v_bal(v_wallets(i)),
               SO_DU_KHA_DUNG = v_bal(v_wallets(i)),
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = v_wallets(i);
    END LOOP;

    FOR i IN 1 .. 3 LOOP
        UPDATE VI_DIEN_TU
           SET SO_DU          = v_bal(v_merchants(i)),
               SO_DU_KHA_DUNG = v_bal(v_merchants(i)),
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = v_merchants(i);
    END LOOP;

    -- Chuyen VI006 sang trang thai TAM_KHOA va ghi nhan nhat ky trang thai khoi tao
    UPDATE VI_DIEN_TU SET TRANG_THAI = 'TAM_KHOA' WHERE MA_VI = 'VI006';
    INSERT INTO NHAT_KY_TRANG_THAI_VI (MA_LOG_TT, MA_VI, TRANG_THAI_CU, TRANG_THAI_MOI, LY_DO, NGUOI_THAY_DOI)
    VALUES (SEQ_LOG_TRANG_THAI.NEXTVAL, 'VI006', 'HOAT_DONG', 'TAM_KHOA',
            N'Tạm khoá ví mẫu để phục vụ kiểm thử ngoại lệ ví bị khoá', 'SYSTEM_INIT');

    COMMIT;

    -- Thu thap thong ke cho Oracle CBO (Cost-Based Optimizer)
    DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/
