-- ============================================================================
-- 07_pkg_quan_ly_vi.sql
-- Package nghiep vu cot loi: Nap, Rut, Chuyen tien, Thanh toan DV, Hoan tien,
-- Khoa/Mo vi va Doi soat hang loat bang Explicit Cursor.
-- Ap dung SAVEPOINT, SELECT FOR UPDATE WAIT, Idempotency va Exception Handling
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_QUAN_LY_VI AS
    -- Bien ngu canh chia se thong tin cho Trigger ghi nhan nhat ky trang thai
    g_ly_do_doi_tt    NVARCHAR2(255) := NULL;
    g_nguoi_thuc_hien VARCHAR2(50)   := NULL;

    -- 1. Nap tien vao vi
    PROCEDURE SP_NAP_TIEN(
        p_ma_vi           IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Nạp tiền vào ví nội bộ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 2. Rut tien khoi vi (co tinh phi giao dich)
    PROCEDURE SP_RUT_TIEN(
        p_ma_vi           IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Rút tiền về tài khoản ngân hàng',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 3. Chuyen tien giua hai vi noi bo (hoac thanh toan dich vu)
    PROCEDURE SP_CHUYEN_TIEN(
        p_ma_vi_nguon     IN  VARCHAR2,
        p_ma_vi_dich      IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Chuyển tiền nội bộ',
        p_ma_loai_gd      IN  VARCHAR2  DEFAULT 'CHUYEN_NOI_BO',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 4. Thanh toan cho doi tac dich vu noi bo
    PROCEDURE SP_THANH_TOAN_DICH_VU(
        p_ma_vi_nguon     IN  VARCHAR2,
        p_ma_doi_tac      IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Thanh toán dịch vụ nội bộ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 5. Hoan tien mot giao dich da thanh cong
    PROCEDURE SP_HOAN_TIEN(
        p_ma_gd_goc       IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_ly_do           IN  NVARCHAR2 DEFAULT N'Hoàn tiền theo yêu cầu nghiệp vụ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd_hoan      OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 6. Khoa / Mo khoa / Dong vinh vien vi
    PROCEDURE SP_KHOA_MO_VI(
        p_ma_vi           IN  VARCHAR2,
        p_trang_thai_moi  IN  VARCHAR2,
        p_ly_do           IN  NVARCHAR2,
        p_nguoi_thuc_hien IN  VARCHAR2 DEFAULT 'ADMIN',
        p_ma_loi          OUT NUMBER,
        p_thong_bao       OUT NVARCHAR2
    );

    -- 7. Doi soat so du vi va so cai ke toan bang Explicit Cursor
    PROCEDURE SP_DOI_SOAT_HANG_LOAT(
        p_tong_vi_kiem_tra OUT NUMBER,
        p_so_vi_lech       OUT NUMBER,
        p_chi_tiet_ket_qua OUT NVARCHAR2
    );
END PKG_QUAN_LY_VI;

CREATE OR REPLACE PACKAGE BODY PKG_QUAN_LY_VI AS

    -- Ham noi bo chuyen doi ma loi he thong sang ma nghiep vu
    FUNCTION fn_map_err_code(p_sqlcode IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_sqlcode
            WHEN -20001 THEN PKG_NGOAI_LE_VI.C_ERR_SO_DU_KHONG_DU
            WHEN -20002 THEN PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG
            WHEN -20003 THEN PKG_NGOAI_LE_VI.C_ERR_VI_BI_KHOA
            WHEN -20004 THEN PKG_NGOAI_LE_VI.C_ERR_VI_KHONG_TON_TAI
            WHEN -20005 THEN PKG_NGOAI_LE_VI.C_ERR_VUOT_HAN_MUC
            WHEN -20006 THEN PKG_NGOAI_LE_VI.C_ERR_SO_TIEN_KHONG_HOPLE
            WHEN -20007 THEN PKG_NGOAI_LE_VI.C_ERR_CHUYEN_CUNG_VI
            WHEN -20008 THEN PKG_NGOAI_LE_VI.C_ERR_VI_DICH_BI_KHOA
            WHEN -20009 THEN PKG_NGOAI_LE_VI.C_ERR_KHONG_THE_HOAN_TIEN
            WHEN -20010 THEN PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI
            WHEN -1     THEN PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG
            WHEN -54    THEN PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI
            WHEN -30006 THEN PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI
            ELSE PKG_NGOAI_LE_VI.C_ERR_HE_THONG
        END;
    END fn_map_err_code;

    -- ------------------------------------------------------------------------
    -- 1. SP_NAP_TIEN
    -- ------------------------------------------------------------------------
    PROCEDURE SP_NAP_TIEN(
        p_ma_vi           IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Nạp tiền vào ví nội bộ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_so_du_cu    VI_DIEN_TU.SO_DU%TYPE;
        v_so_du_moi   VI_DIEN_TU.SO_DU%TYPE;
        v_trang_thai  VI_DIEN_TU.TRANG_THAI%TYPE;
        v_cnt_dup     NUMBER := 0;
        v_phi         NUMBER(18, 2) := 0;
    BEGIN
        p_ma_gd           := NULL;
        p_ma_loi          := 0;
        p_ma_loi_nghiep_vu := 'SUCCESS';
        p_thong_bao       := N'Nạp tiền thành công.';

        SAVEPOINT sp_nap_tien;

        IF p_so_tien IS NULL OR p_so_tien <= 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_so_tien_khong_hop_le;
        END IF;

        IF TRIM(p_ma_tham_chieu) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20006, N'Mã tham chiếu giao dịch không được để trống.');
        END IF;

        SELECT COUNT(*) INTO v_cnt_dup
          FROM GIAO_DICH
         WHERE MA_THAM_CHIEU = p_ma_tham_chieu;

        IF v_cnt_dup > 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap;
        END IF;

        BEGIN
            SELECT SO_DU, TRANG_THAI
              INTO v_so_du_cu, v_trang_thai
              FROM VI_DIEN_TU
             WHERE MA_VI = p_ma_vi
               FOR UPDATE WAIT 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
        END;

        IF v_trang_thai <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_bi_khoa;
        END IF;

        v_phi       := FN_TINH_PHI_GIAO_DICH('NAP_TIEN', p_so_tien);
        v_so_du_moi := v_so_du_cu + p_so_tien - v_phi;
        p_ma_gd     := SEQ_GIAO_DICH.NEXTVAL;

        INSERT INTO GIAO_DICH (
            MA_GD, MA_THAM_CHIEU, MA_VI_NGUON, MA_VI_DICH, MA_LOAI_GD,
            SO_TIEN, PHI_GD, TONG_TIEN, NOI_DUNG, TRANG_THAI,
            NGUOI_THUC_HIEN, NGAY_TAO, NGAY_HOAN_TAT
        ) VALUES (
            p_ma_gd, p_ma_tham_chieu, NULL, p_ma_vi, 'NAP_TIEN',
            p_so_tien, v_phi, p_so_tien, p_noi_dung, 'THANH_CONG',
            NVL(p_nguoi_thuc_hien, 'API_USER'), SYSTIMESTAMP, SYSTIMESTAMP
        );

        UPDATE VI_DIEN_TU
           SET SO_DU          = v_so_du_moi,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG + (p_so_tien - v_phi),
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = p_ma_vi;

        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd, p_ma_vi, 'GHI_CO', p_so_tien - v_phi,
            v_so_du_cu, v_so_du_moi, p_noi_dung
        );

        IF p_tu_dong_commit = 1 THEN
            COMMIT;
        END IF;

        p_thong_bao := N'Nạp tiền thành công ' || TO_CHAR(p_so_tien, 'FM999,999,999,990') ||
                       N' VNĐ vào ví ' || p_ma_vi || N'. Số dư mới: ' ||
                       TO_CHAR(v_so_du_moi, 'FM999,999,999,990') || N' VNĐ.';
    EXCEPTION
        WHEN PKG_NGOAI_LE_VI.e_giao_dich_trung_lap OR DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp_nap_tien;
            p_ma_loi           := -20002;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20002);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_NAP_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;

        WHEN PKG_NGOAI_LE_VI.e_ora_resource_busy OR PKG_NGOAI_LE_VI.e_ora_wait_timeout THEN
            ROLLBACK TO sp_nap_tien;
            p_ma_loi           := -20010;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20010);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_NAP_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_khoa_dong_thoi; END IF;

        WHEN OTHERS THEN
            ROLLBACK TO sp_nap_tien;
            p_ma_loi           := SQLCODE;
            p_ma_loi_nghiep_vu := fn_map_err_code(SQLCODE);
            p_thong_bao        := CASE
                WHEN SQLCODE BETWEEN -20010 AND -20001 THEN PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(SQLCODE)
                ELSE N'Lỗi nạp tiền: ' || SUBSTR(SQLERRM, 1, 300)
            END;
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_NAP_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;
    END SP_NAP_TIEN;

    -- ------------------------------------------------------------------------
    -- 2. SP_RUT_TIEN
    -- ------------------------------------------------------------------------
    PROCEDURE SP_RUT_TIEN(
        p_ma_vi           IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Rút tiền về tài khoản ngân hàng',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_so_du_cu       VI_DIEN_TU.SO_DU%TYPE;
        v_kha_dung       VI_DIEN_TU.SO_DU_KHA_DUNG%TYPE;
        v_han_muc_ngay   VI_DIEN_TU.HAN_MUC_NGAY%TYPE;
        v_trang_thai     VI_DIEN_TU.TRANG_THAI%TYPE;
        v_phi            NUMBER(18, 2);
        v_tong_tru       NUMBER(18, 2);
        v_so_du_moi      NUMBER(18, 2);
        v_da_chi_hom_nay NUMBER(18, 2);
        v_cnt_dup        NUMBER := 0;
    BEGIN
        p_ma_gd            := NULL;
        p_ma_loi           := 0;
        p_ma_loi_nghiep_vu := 'SUCCESS';
        p_thong_bao        := N'Rút tiền thành công.';

        SAVEPOINT sp_rut_tien;

        IF p_so_tien IS NULL OR p_so_tien <= 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_so_tien_khong_hop_le;
        END IF;

        IF TRIM(p_ma_tham_chieu) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20006, N'Mã tham chiếu không được để trống.');
        END IF;

        SELECT COUNT(*) INTO v_cnt_dup
          FROM GIAO_DICH
         WHERE MA_THAM_CHIEU = p_ma_tham_chieu;

        IF v_cnt_dup > 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap;
        END IF;

        BEGIN
            SELECT SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI
              INTO v_so_du_cu, v_kha_dung, v_han_muc_ngay, v_trang_thai
              FROM VI_DIEN_TU
             WHERE MA_VI = p_ma_vi
               FOR UPDATE WAIT 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
        END;

        IF v_trang_thai <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_bi_khoa;
        END IF;

        v_phi      := FN_TINH_PHI_GIAO_DICH('RUT_TIEN', p_so_tien);
        v_tong_tru := p_so_tien + v_phi;

        IF v_kha_dung < v_tong_tru THEN
            RAISE PKG_NGOAI_LE_VI.e_so_du_khong_du;
        END IF;

        v_da_chi_hom_nay := FN_TONG_CHI_TRONG_NGAY(p_ma_vi, SYSDATE);
        IF (v_da_chi_hom_nay + v_tong_tru) > v_han_muc_ngay THEN
            RAISE PKG_NGOAI_LE_VI.e_vuot_han_muc_ngay;
        END IF;

        v_so_du_moi := v_so_du_cu - v_tong_tru;
        p_ma_gd     := SEQ_GIAO_DICH.NEXTVAL;

        INSERT INTO GIAO_DICH (
            MA_GD, MA_THAM_CHIEU, MA_VI_NGUON, MA_VI_DICH, MA_LOAI_GD,
            SO_TIEN, PHI_GD, TONG_TIEN, NOI_DUNG, TRANG_THAI,
            NGUOI_THUC_HIEN, NGAY_TAO, NGAY_HOAN_TAT
        ) VALUES (
            p_ma_gd, p_ma_tham_chieu, p_ma_vi, NULL, 'RUT_TIEN',
            p_so_tien, v_phi, v_tong_tru, p_noi_dung, 'THANH_CONG',
            NVL(p_nguoi_thuc_hien, 'API_USER'), SYSTIMESTAMP, SYSTIMESTAMP
        );

        UPDATE VI_DIEN_TU
           SET SO_DU          = v_so_du_moi,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG - v_tong_tru,
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = p_ma_vi;

        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd, p_ma_vi, 'GHI_NO', v_tong_tru,
            v_so_du_cu, v_so_du_moi, p_noi_dung || N' (Phí: ' || v_phi || N'đ)'
        );

        IF p_tu_dong_commit = 1 THEN
            COMMIT;
        END IF;

        p_thong_bao := N'Rút tiền thành công ' || TO_CHAR(p_so_tien, 'FM999,999,999,990') ||
                       N' VNĐ (Phí ' || TO_CHAR(v_phi, 'FM999,999,990') || N' VNĐ). Số dư còn lại: ' ||
                       TO_CHAR(v_so_du_moi, 'FM999,999,999,990') || N' VNĐ.';
    EXCEPTION
        WHEN PKG_NGOAI_LE_VI.e_giao_dich_trung_lap OR DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp_rut_tien;
            p_ma_loi           := -20002;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20002);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_RUT_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;

        WHEN PKG_NGOAI_LE_VI.e_ora_resource_busy OR PKG_NGOAI_LE_VI.e_ora_wait_timeout THEN
            ROLLBACK TO sp_rut_tien;
            p_ma_loi           := -20010;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20010);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_RUT_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_khoa_dong_thoi; END IF;

        WHEN OTHERS THEN
            ROLLBACK TO sp_rut_tien;
            p_ma_loi           := SQLCODE;
            p_ma_loi_nghiep_vu := fn_map_err_code(SQLCODE);
            p_thong_bao        := CASE
                WHEN SQLCODE BETWEEN -20010 AND -20001 THEN PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(SQLCODE)
                ELSE N'Lỗi rút tiền: ' || SUBSTR(SQLERRM, 1, 300)
            END;
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_RUT_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'VI=' || p_ma_vi || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;
    END SP_RUT_TIEN;

    -- ------------------------------------------------------------------------
    -- 3. SP_CHUYEN_TIEN (Khoa theo thu tu tang dan MA_VI chong Deadlock)
    -- ------------------------------------------------------------------------
    PROCEDURE SP_CHUYEN_TIEN(
        p_ma_vi_nguon     IN  VARCHAR2,
        p_ma_vi_dich      IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Chuyển tiền nội bộ',
        p_ma_loai_gd      IN  VARCHAR2  DEFAULT 'CHUYEN_NOI_BO',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_src_du          VI_DIEN_TU.SO_DU%TYPE;
        v_src_kd          VI_DIEN_TU.SO_DU_KHA_DUNG%TYPE;
        v_src_hm          VI_DIEN_TU.HAN_MUC_NGAY%TYPE;
        v_src_tt          VI_DIEN_TU.TRANG_THAI%TYPE;

        v_dst_du          VI_DIEN_TU.SO_DU%TYPE;
        v_dst_tt          VI_DIEN_TU.TRANG_THAI%TYPE;

        v_phi             NUMBER(18, 2);
        v_tong_tru        NUMBER(18, 2);
        v_da_chi_hom_nay  NUMBER(18, 2);
        v_cnt_dup         NUMBER := 0;
        v_loai_gd         VARCHAR2(30) := NVL(p_ma_loai_gd, 'CHUYEN_NOI_BO');
    BEGIN
        p_ma_gd            := NULL;
        p_ma_loi           := 0;
        p_ma_loi_nghiep_vu := 'SUCCESS';
        p_thong_bao        := N'Chuyển tiền thành công.';

        SAVEPOINT sp_chuyen_tien;

        -- Kiem tra hop le dau vao
        IF p_so_tien IS NULL OR p_so_tien <= 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_so_tien_khong_hop_le;
        END IF;

        IF p_ma_vi_nguon = p_ma_vi_dich THEN
            RAISE PKG_NGOAI_LE_VI.e_chuyen_cung_vi;
        END IF;

        IF TRIM(p_ma_tham_chieu) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20006, N'Mã tham chiếu giao dịch không được để trống.');
        END IF;

        -- Kiem tra giao dich trung lap (Idempotency)
        SELECT COUNT(*) INTO v_cnt_dup
          FROM GIAO_DICH
         WHERE MA_THAM_CHIEU = p_ma_tham_chieu;

        IF v_cnt_dup > 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap;
        END IF;

        -- Khoa bi quan (Pessimistic Locking) theo thu tu tang dan cua MA_VI de tranh Deadlock
        IF p_ma_vi_nguon < p_ma_vi_dich THEN
            BEGIN
                SELECT SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI
                  INTO v_src_du, v_src_kd, v_src_hm, v_src_tt
                  FROM VI_DIEN_TU
                 WHERE MA_VI = p_ma_vi_nguon
                   FOR UPDATE WAIT 2;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
            END;

            BEGIN
                SELECT SO_DU, TRANG_THAI
                  INTO v_dst_du, v_dst_tt
                  FROM VI_DIEN_TU
                 WHERE MA_VI = p_ma_vi_dich
                   FOR UPDATE WAIT 2;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
            END;
        ELSE
            BEGIN
                SELECT SO_DU, TRANG_THAI
                  INTO v_dst_du, v_dst_tt
                  FROM VI_DIEN_TU
                 WHERE MA_VI = p_ma_vi_dich
                   FOR UPDATE WAIT 2;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
            END;

            BEGIN
                SELECT SO_DU, SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI
                  INTO v_src_du, v_src_kd, v_src_hm, v_src_tt
                  FROM VI_DIEN_TU
                 WHERE MA_VI = p_ma_vi_nguon
                   FOR UPDATE WAIT 2;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai;
            END;
        END IF;

        -- Kiem tra trang thai 2 vi
        IF v_src_tt <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_bi_khoa;
        END IF;

        IF v_dst_tt <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_dich_bi_khoa;
        END IF;

        -- Tinh phi va kiem tra so du
        v_phi      := FN_TINH_PHI_GIAO_DICH(v_loai_gd, p_so_tien);
        v_tong_tru := p_so_tien + v_phi;

        IF v_src_kd < v_tong_tru THEN
            RAISE PKG_NGOAI_LE_VI.e_so_du_khong_du;
        END IF;

        -- Kiem tra han muc chi tieu trong ngay
        v_da_chi_hom_nay := FN_TONG_CHI_TRONG_NGAY(p_ma_vi_nguon, SYSDATE);
        IF (v_da_chi_hom_nay + v_tong_tru) > v_src_hm THEN
            RAISE PKG_NGOAI_LE_VI.e_vuot_han_muc_ngay;
        END IF;

        -- Ghi nhan giao dich (Unique Index UQ_GD_THAM_CHIEU bao ve them o tang CSDL)
        p_ma_gd := SEQ_GIAO_DICH.NEXTVAL;

        INSERT INTO GIAO_DICH (
            MA_GD, MA_THAM_CHIEU, MA_VI_NGUON, MA_VI_DICH, MA_LOAI_GD,
            SO_TIEN, PHI_GD, TONG_TIEN, NOI_DUNG, TRANG_THAI,
            NGUOI_THUC_HIEN, NGAY_TAO, NGAY_HOAN_TAT
        ) VALUES (
            p_ma_gd, p_ma_tham_chieu, p_ma_vi_nguon, p_ma_vi_dich, v_loai_gd,
            p_so_tien, v_phi, v_tong_tru, p_noi_dung, 'THANH_CONG',
            NVL(p_nguoi_thuc_hien, 'API_USER'), SYSTIMESTAMP, SYSTIMESTAMP
        );

        -- Cap nhat so du vi nguon (ghi no) va vi dich (ghi co)
        UPDATE VI_DIEN_TU
           SET SO_DU          = SO_DU - v_tong_tru,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG - v_tong_tru,
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = p_ma_vi_nguon;

        UPDATE VI_DIEN_TU
           SET SO_DU          = SO_DU + p_so_tien,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG + p_so_tien,
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = p_ma_vi_dich;

        -- Ghi so cai ke toan kep
        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd, p_ma_vi_nguon, 'GHI_NO', v_tong_tru,
            v_src_du, v_src_du - v_tong_tru, p_noi_dung
        );

        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd, p_ma_vi_dich, 'GHI_CO', p_so_tien,
            v_dst_du, v_dst_du + p_so_tien, p_noi_dung
        );

        IF p_tu_dong_commit = 1 THEN
            COMMIT;
        END IF;

        p_thong_bao := N'Chuyển thành công ' || TO_CHAR(p_so_tien, 'FM999,999,999,990') ||
                       N' VNĐ từ ' || p_ma_vi_nguon || N' sang ' || p_ma_vi_dich || N'.';
    EXCEPTION
        WHEN PKG_NGOAI_LE_VI.e_giao_dich_trung_lap OR DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp_chuyen_tien;
            p_ma_loi           := -20002;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20002);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_CHUYEN_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'SRC=' || p_ma_vi_nguon || ';DST=' || p_ma_vi_dich || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap; END IF;

        WHEN PKG_NGOAI_LE_VI.e_ora_resource_busy OR PKG_NGOAI_LE_VI.e_ora_wait_timeout THEN
            ROLLBACK TO sp_chuyen_tien;
            p_ma_loi           := -20010;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_KHOA_DONG_THOI;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20010);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_CHUYEN_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'SRC=' || p_ma_vi_nguon || ';DST=' || p_ma_vi_dich || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_khoa_dong_thoi; END IF;

        WHEN OTHERS THEN
            ROLLBACK TO sp_chuyen_tien;
            p_ma_loi           := SQLCODE;
            p_ma_loi_nghiep_vu := fn_map_err_code(SQLCODE);
            p_thong_bao        := CASE
                WHEN SQLCODE BETWEEN -20010 AND -20001 THEN PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(SQLCODE)
                ELSE N'Lỗi chuyển tiền: ' || SUBSTR(SQLERRM, 1, 300)
            END;
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_CHUYEN_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'SRC=' || p_ma_vi_nguon || ';DST=' || p_ma_vi_dich || ';SO_TIEN=' || p_so_tien,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;
    END SP_CHUYEN_TIEN;

    -- ------------------------------------------------------------------------
    -- 4. SP_THANH_TOAN_DICH_VU
    -- ------------------------------------------------------------------------
    PROCEDURE SP_THANH_TOAN_DICH_VU(
        p_ma_vi_nguon     IN  VARCHAR2,
        p_ma_doi_tac      IN  VARCHAR2,
        p_so_tien         IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_noi_dung        IN  NVARCHAR2 DEFAULT N'Thanh toán dịch vụ nội bộ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd           OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_ma_vi_nhan  DOI_TAC_DICH_VU.MA_VI_NHAN%TYPE;
        v_ten_dt      DOI_TAC_DICH_VU.TEN_DOI_TAC%TYPE;
        v_tt_dt       DOI_TAC_DICH_VU.TRANG_THAI%TYPE;
    BEGIN
        SELECT MA_VI_NHAN, TEN_DOI_TAC, TRANG_THAI
          INTO v_ma_vi_nhan, v_ten_dt, v_tt_dt
          FROM DOI_TAC_DICH_VU
         WHERE MA_DOI_TAC = p_ma_doi_tac;

        IF v_tt_dt <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_dich_bi_khoa;
        END IF;

        SP_CHUYEN_TIEN(
            p_ma_vi_nguon      => p_ma_vi_nguon,
            p_ma_vi_dich       => v_ma_vi_nhan,
            p_so_tien          => p_so_tien,
            p_ma_tham_chieu    => p_ma_tham_chieu,
            p_noi_dung         => NVL(p_noi_dung, N'Thanh toán tại ' || v_ten_dt),
            p_ma_loai_gd       => 'THANH_TOAN_DV',
            p_nguoi_thuc_hien  => p_nguoi_thuc_hien,
            p_tu_dong_commit   => p_tu_dong_commit,
            p_nem_ngoai_le     => p_nem_ngoai_le,
            p_ma_gd            => p_ma_gd,
            p_ma_loi           => p_ma_loi,
            p_ma_loi_nghiep_vu => p_ma_loi_nghiep_vu,
            p_thong_bao        => p_thong_bao
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_ma_gd            := NULL;
            p_ma_loi           := -20004;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_VI_KHONG_TON_TAI;
            p_thong_bao        := N'Đối tác dịch vụ không tồn tại: ' || p_ma_doi_tac;
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_THANH_TOAN_DICH_VU', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'SRC=' || p_ma_vi_nguon || ';DOI_TAC=' || p_ma_doi_tac,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_vi_khong_ton_tai; END IF;
        WHEN PKG_NGOAI_LE_VI.e_vi_dich_bi_khoa THEN
            p_ma_gd            := NULL;
            p_ma_loi           := -20008;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_VI_DICH_BI_KHOA;
            p_thong_bao        := N'Đối tác dịch vụ đang tạm ngưng nhận thanh toán.';
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_THANH_TOAN_DICH_VU', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'SRC=' || p_ma_vi_nguon || ';DOI_TAC=' || p_ma_doi_tac,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;
    END SP_THANH_TOAN_DICH_VU;

    -- ------------------------------------------------------------------------
    -- 5. SP_HOAN_TIEN
    -- ------------------------------------------------------------------------
    PROCEDURE SP_HOAN_TIEN(
        p_ma_gd_goc       IN  NUMBER,
        p_ma_tham_chieu   IN  VARCHAR2,
        p_ly_do           IN  NVARCHAR2 DEFAULT N'Hoàn tiền theo yêu cầu nghiệp vụ',
        p_nguoi_thuc_hien IN  VARCHAR2  DEFAULT 'API_USER',
        p_tu_dong_commit  IN  NUMBER    DEFAULT 1,
        p_nem_ngoai_le    IN  NUMBER    DEFAULT 0,
        p_ma_gd_hoan      OUT NUMBER,
        p_ma_loi          OUT NUMBER,
        p_ma_loi_nghiep_vu OUT VARCHAR2,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_gd_goc   GIAO_DICH%ROWTYPE;
        v_du_nguon NUMBER(18, 2);
        v_du_dich  NUMBER(18, 2);
        v_tt_nguon VARCHAR2(20);
        v_tt_dich  VARCHAR2(20);
        v_cnt_dup  NUMBER := 0;
    BEGIN
        p_ma_gd_hoan       := NULL;
        p_ma_loi           := 0;
        p_ma_loi_nghiep_vu := 'SUCCESS';
        p_thong_bao        := N'Hoàn tiền thành công.';

        SAVEPOINT sp_hoan_tien;

        SELECT COUNT(*) INTO v_cnt_dup
          FROM GIAO_DICH
         WHERE MA_THAM_CHIEU = p_ma_tham_chieu;

        IF v_cnt_dup > 0 THEN
            RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap;
        END IF;

        BEGIN
            SELECT *
              INTO v_gd_goc
              FROM GIAO_DICH
             WHERE MA_GD = p_ma_gd_goc
               FOR UPDATE WAIT 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE PKG_NGOAI_LE_VI.e_khong_the_hoan_tien;
        END;

        IF v_gd_goc.TRANG_THAI <> 'THANH_CONG'
           OR v_gd_goc.MA_LOAI_GD NOT IN ('CHUYEN_NOI_BO', 'THANH_TOAN_DV')
           OR v_gd_goc.MA_VI_NGUON IS NULL
           OR v_gd_goc.MA_VI_DICH IS NULL THEN
            RAISE PKG_NGOAI_LE_VI.e_khong_the_hoan_tien;
        END IF;

        -- Khoa 2 vi theo thu tu tang dan (vi dich goc tro thanh vi hoan tra, vi nguon goc nhan lai tien)
        IF v_gd_goc.MA_VI_NGUON < v_gd_goc.MA_VI_DICH THEN
            SELECT SO_DU, TRANG_THAI INTO v_du_nguon, v_tt_nguon
              FROM VI_DIEN_TU WHERE MA_VI = v_gd_goc.MA_VI_NGUON FOR UPDATE WAIT 2;
            SELECT SO_DU, TRANG_THAI INTO v_du_dich, v_tt_dich
              FROM VI_DIEN_TU WHERE MA_VI = v_gd_goc.MA_VI_DICH FOR UPDATE WAIT 2;
        ELSE
            SELECT SO_DU, TRANG_THAI INTO v_du_dich, v_tt_dich
              FROM VI_DIEN_TU WHERE MA_VI = v_gd_goc.MA_VI_DICH FOR UPDATE WAIT 2;
            SELECT SO_DU, TRANG_THAI INTO v_du_nguon, v_tt_nguon
              FROM VI_DIEN_TU WHERE MA_VI = v_gd_goc.MA_VI_NGUON FOR UPDATE WAIT 2;
        END IF;

        IF v_tt_nguon <> 'HOAT_DONG' OR v_tt_dich <> 'HOAT_DONG' THEN
            RAISE PKG_NGOAI_LE_VI.e_vi_bi_khoa;
        END IF;

        IF v_du_dich < v_gd_goc.SO_TIEN THEN
            RAISE PKG_NGOAI_LE_VI.e_so_du_khong_du;
        END IF;

        p_ma_gd_hoan := SEQ_GIAO_DICH.NEXTVAL;

        UPDATE GIAO_DICH
           SET TRANG_THAI = 'DA_HOAN_TIEN'
         WHERE MA_GD = p_ma_gd_goc;

        INSERT INTO GIAO_DICH (
            MA_GD, MA_THAM_CHIEU, MA_VI_NGUON, MA_VI_DICH, MA_LOAI_GD, MA_GD_GOC,
            SO_TIEN, PHI_GD, TONG_TIEN, NOI_DUNG, TRANG_THAI,
            NGUOI_THUC_HIEN, NGAY_TAO, NGAY_HOAN_TAT
        ) VALUES (
            p_ma_gd_hoan, p_ma_tham_chieu, v_gd_goc.MA_VI_DICH, v_gd_goc.MA_VI_NGUON,
            'HOAN_TIEN', p_ma_gd_goc, v_gd_goc.SO_TIEN, 0, v_gd_goc.SO_TIEN,
            p_ly_do, 'THANH_CONG', NVL(p_nguoi_thuc_hien, 'API_USER'), SYSTIMESTAMP, SYSTIMESTAMP
        );

        UPDATE VI_DIEN_TU
           SET SO_DU          = SO_DU - v_gd_goc.SO_TIEN,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG - v_gd_goc.SO_TIEN,
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = v_gd_goc.MA_VI_DICH;

        UPDATE VI_DIEN_TU
           SET SO_DU          = SO_DU + v_gd_goc.SO_TIEN,
               SO_DU_KHA_DUNG = SO_DU_KHA_DUNG + v_gd_goc.SO_TIEN,
               VERSION_LOCK   = VERSION_LOCK + 1,
               NGAY_CAP_NHAT  = SYSTIMESTAMP
         WHERE MA_VI = v_gd_goc.MA_VI_NGUON;

        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd_hoan, v_gd_goc.MA_VI_DICH, 'GHI_NO', v_gd_goc.SO_TIEN,
            v_du_dich, v_du_dich - v_gd_goc.SO_TIEN, N'Hoàn trả cho GD #' || p_ma_gd_goc
        );

        INSERT INTO CHI_TIET_SO_CAI (
            MA_BUT_TOAN, MA_GD, MA_VI, LOAI_BUT_TOAN, SO_TIEN, SO_DU_TRUOC, SO_DU_SAU, MO_TA
        ) VALUES (
            SEQ_SO_CAI.NEXTVAL, p_ma_gd_hoan, v_gd_goc.MA_VI_NGUON, 'GHI_CO', v_gd_goc.SO_TIEN,
            v_du_nguon, v_du_nguon + v_gd_goc.SO_TIEN, N'Nhận hoàn tiền từ GD #' || p_ma_gd_goc
        );

        IF p_tu_dong_commit = 1 THEN
            COMMIT;
        END IF;

        p_thong_bao := N'Hoàn tiền thành công ' || TO_CHAR(v_gd_goc.SO_TIEN, 'FM999,999,999,990') ||
                       N' VNĐ cho giao dịch #' || p_ma_gd_goc || N'.';
    EXCEPTION
        WHEN PKG_NGOAI_LE_VI.e_giao_dich_trung_lap OR DUP_VAL_ON_INDEX THEN
            ROLLBACK TO sp_hoan_tien;
            p_ma_loi           := -20002;
            p_ma_loi_nghiep_vu := PKG_NGOAI_LE_VI.C_ERR_GIAO_DICH_TRUNG;
            p_thong_bao        := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20002);
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_HOAN_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'MA_GD_GOC=' || p_ma_gd_goc,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE PKG_NGOAI_LE_VI.e_giao_dich_trung_lap; END IF;

        WHEN OTHERS THEN
            ROLLBACK TO sp_hoan_tien;
            p_ma_loi           := SQLCODE;
            p_ma_loi_nghiep_vu := fn_map_err_code(SQLCODE);
            p_thong_bao        := CASE
                WHEN SQLCODE BETWEEN -20010 AND -20001 THEN PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(SQLCODE)
                ELSE N'Lỗi hoàn tiền: ' || SUBSTR(SQLERRM, 1, 300)
            END;
            PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                p_ma_tham_chieu, 'PKG_QUAN_LY_VI.SP_HOAN_TIEN', p_ma_loi, p_ma_loi_nghiep_vu,
                p_thong_bao, 'MA_GD_GOC=' || p_ma_gd_goc,
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, p_nguoi_thuc_hien
            );
            IF p_nem_ngoai_le = 1 THEN RAISE; END IF;
    END SP_HOAN_TIEN;

    -- ------------------------------------------------------------------------
    -- 6. SP_KHOA_MO_VI
    -- ------------------------------------------------------------------------
    PROCEDURE SP_KHOA_MO_VI(
        p_ma_vi           IN  VARCHAR2,
        p_trang_thai_moi  IN  VARCHAR2,
        p_ly_do           IN  NVARCHAR2,
        p_nguoi_thuc_hien IN  VARCHAR2 DEFAULT 'ADMIN',
        p_ma_loi          OUT NUMBER,
        p_thong_bao       OUT NVARCHAR2
    ) IS
        v_trang_thai_cu VI_DIEN_TU.TRANG_THAI%TYPE;
    BEGIN
        p_ma_loi    := 0;
        p_thong_bao := N'Cập nhật trạng thái ví thành công.';

        IF p_trang_thai_moi NOT IN ('HOAT_DONG', 'TAM_KHOA', 'DONG_VINH_VIEN') THEN
            RAISE_APPLICATION_ERROR(-20006, N'Trạng thái ví không hợp lệ: ' || p_trang_thai_moi);
        END IF;

        SELECT TRANG_THAI INTO v_trang_thai_cu
          FROM VI_DIEN_TU
         WHERE MA_VI = p_ma_vi
           FOR UPDATE;

        IF v_trang_thai_cu = 'DONG_VINH_VIEN' THEN
            RAISE_APPLICATION_ERROR(-20003, N'Ví đã đóng vĩnh viễn, không thể thay đổi trạng thái.');
        END IF;

        g_ly_do_doi_tt    := p_ly_do;
        g_nguoi_thuc_hien := NVL(p_nguoi_thuc_hien, 'ADMIN');

        UPDATE VI_DIEN_TU
           SET TRANG_THAI    = p_trang_thai_moi,
               NGAY_CAP_NHAT = SYSTIMESTAMP
         WHERE MA_VI = p_ma_vi;

        g_ly_do_doi_tt    := NULL;
        g_nguoi_thuc_hien := NULL;
        COMMIT;

        p_thong_bao := N'Đã chuyển ví ' || p_ma_vi || N' từ ' || v_trang_thai_cu || N' sang ' || p_trang_thai_moi || N'.';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            g_ly_do_doi_tt    := NULL;
            g_nguoi_thuc_hien := NULL;
            p_ma_loi          := -20004;
            p_thong_bao       := PKG_NGOAI_LE_VI.FN_LAY_THONG_DIEP_LOI(-20004);
        WHEN OTHERS THEN
            g_ly_do_doi_tt    := NULL;
            g_nguoi_thuc_hien := NULL;
            ROLLBACK;
            p_ma_loi    := SQLCODE;
            p_thong_bao := SUBSTR(SQLERRM, 1, 300);
    END SP_KHOA_MO_VI;

    -- ------------------------------------------------------------------------
    -- 7. SP_DOI_SOAT_HANG_LOAT (Minh hoa Explicit Cursor + kiem tra can bang so cai)
    -- ------------------------------------------------------------------------
    PROCEDURE SP_DOI_SOAT_HANG_LOAT(
        p_tong_vi_kiem_tra OUT NUMBER,
        p_so_vi_lech       OUT NUMBER,
        p_chi_tiet_ket_qua OUT NVARCHAR2
    ) IS
        CURSOR c_vi_doi_soat IS
            SELECT v.MA_VI,
                   v.SO_DU,
                   NVL(SUM(CASE
                       WHEN sc.LOAI_BUT_TOAN = 'GHI_CO' THEN sc.SO_TIEN
                       WHEN sc.LOAI_BUT_TOAN = 'GHI_NO' THEN -sc.SO_TIEN
                       ELSE 0
                   END), 0) AS SO_DU_SO_CAI
              FROM VI_DIEN_TU v
              LEFT JOIN CHI_TIET_SO_CAI sc ON v.MA_VI = sc.MA_VI
             GROUP BY v.MA_VI, v.SO_DU
             ORDER BY v.MA_VI;

        v_rec      c_vi_doi_soat%ROWTYPE;
        v_danh_sach NVARCHAR2(2000) := N'';
    BEGIN
        p_tong_vi_kiem_tra := 0;
        p_so_vi_lech       := 0;

        OPEN c_vi_doi_soat;
        LOOP
            FETCH c_vi_doi_soat INTO v_rec;
            EXIT WHEN c_vi_doi_soat%NOTFOUND;

            p_tong_vi_kiem_tra := p_tong_vi_kiem_tra + 1;

            IF v_rec.SO_DU <> v_rec.SO_DU_SO_CAI THEN
                p_so_vi_lech := p_so_vi_lech + 1;
                v_danh_sach := v_danh_sach || v_rec.MA_VI ||
                               N' (Ví=' || v_rec.SO_DU || N', Sổ cái=' || v_rec.SO_DU_SO_CAI || N'); ';

                PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(
                    'RECON-' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'),
                    'PKG_QUAN_LY_VI.SP_DOI_SOAT_HANG_LOAT',
                    -20099,
                    'ERR_LEDGER_MISMATCH',
                    N'Phát hiện sai lệch số dư ví và sổ cái tại ' || v_rec.MA_VI,
                    'SO_DU=' || v_rec.SO_DU || ';SO_CAI=' || v_rec.SO_DU_SO_CAI,
                    NULL,
                    'RECON_BATCH'
                );
            END IF;
        END LOOP;
        CLOSE c_vi_doi_soat;

        IF p_so_vi_lech = 0 THEN
            p_chi_tiet_ket_qua := N'Đối soát hoàn tất ' || p_tong_vi_kiem_tra ||
                                  N' ví: 100% khớp tuyệt đối với Sổ cái kế toán kép.';
        ELSE
            p_chi_tiet_ket_qua := N'Cảnh báo: Phát hiện ' || p_so_vi_lech || N'/' || p_tong_vi_kiem_tra ||
                                  N' ví bị lệch: ' || v_danh_sach;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF c_vi_doi_soat%ISOPEN THEN
                CLOSE c_vi_doi_soat;
            END IF;
            RAISE;
    END SP_DOI_SOAT_HANG_LOAT;

END PKG_QUAN_LY_VI;
