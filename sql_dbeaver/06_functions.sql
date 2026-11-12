-- ============================================================================
-- 06_functions.sql
-- Cac Stored Functions doc lap phuc vu tinh phi, kiem tra dieu kien, xep hang vi
-- Minh hoa ro ham goi trong SQL thuan va Oracle 23ai native SQL BOOLEAN
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

-- 1. Ham tinh phi giao dich theo bieu phi trong LOAI_GIAO_DICH (SQL-callable)
CREATE OR REPLACE FUNCTION FN_TINH_PHI_GIAO_DICH(
    p_ma_loai_gd IN VARCHAR2,
    p_so_tien    IN NUMBER
) RETURN NUMBER IS
    v_phi_co_dinh LOAI_GIAO_DICH.PHI_CO_DINH%TYPE;
    v_ty_le_phi   LOAI_GIAO_DICH.TY_LE_PHI%TYPE;
    v_phi_toi_da  LOAI_GIAO_DICH.PHI_TOI_DA%TYPE;
    v_phi_tinh    NUMBER(18, 2);
BEGIN
    IF p_so_tien IS NULL OR p_so_tien <= 0 THEN
        RAISE PKG_NGOAI_LE_VI.e_so_tien_khong_hop_le;
    END IF;

    SELECT PHI_CO_DINH, TY_LE_PHI, PHI_TOI_DA
      INTO v_phi_co_dinh, v_ty_le_phi, v_phi_toi_da
      FROM LOAI_GIAO_DICH
     WHERE MA_LOAI_GD = p_ma_loai_gd;

    v_phi_tinh := ROUND(v_phi_co_dinh + (p_so_tien * v_ty_le_phi), 2);

    IF v_phi_toi_da > 0 AND v_phi_tinh > v_phi_toi_da THEN
        v_phi_tinh := v_phi_toi_da;
    END IF;

    RETURN v_phi_tinh;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Khong tim thay loai giao dich: ' || p_ma_loai_gd);
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20006, 'Gia tri so tien tinh phi khong hop le.');
END FN_TINH_PHI_GIAO_DICH;

-- 2. Ham tinh tong chi tieu hop le trong ngay cua mot vi (SQL-callable)
CREATE OR REPLACE FUNCTION FN_TONG_CHI_TRONG_NGAY(
    p_ma_vi IN VARCHAR2,
    p_ngay  IN DATE DEFAULT SYSDATE
) RETURN NUMBER IS
    v_tong_chi NUMBER(18, 2) := 0;
    v_tu_ngay  TIMESTAMP;
    v_den_ngay TIMESTAMP;
BEGIN
    v_tu_ngay  := CAST(TRUNC(NVL(p_ngay, SYSDATE)) AS TIMESTAMP);
    v_den_ngay := v_tu_ngay + NUMTODSINTERVAL(1, 'DAY');

    SELECT NVL(SUM(gd.TONG_TIEN), 0)
      INTO v_tong_chi
      FROM GIAO_DICH gd
      JOIN LOAI_GIAO_DICH lgd ON gd.MA_LOAI_GD = lgd.MA_LOAI_GD
     WHERE gd.MA_VI_NGUON = p_ma_vi
       AND gd.TRANG_THAI IN ('CHO_XU_LY', 'THANH_CONG')
       AND lgd.CO_TINH_HAN_MUC = 1
       AND gd.NGAY_TAO >= v_tu_ngay
       AND gd.NGAY_TAO < v_den_ngay;

    RETURN v_tong_chi;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END FN_TONG_CHI_TRONG_NGAY;

-- 3. Ham kiem tra trang thai hoat dong cua vi tra ve BOOLEAN (Tinh nang Oracle 23ai native BOOLEAN trong SQL)
CREATE OR REPLACE FUNCTION FN_KIEM_TRA_VI_HOAT_DONG(
    p_ma_vi IN VARCHAR2
) RETURN BOOLEAN IS
    v_trang_thai VI_DIEN_TU.TRANG_THAI%TYPE;
BEGIN
    SELECT TRANG_THAI
      INTO v_trang_thai
      FROM VI_DIEN_TU
     WHERE MA_VI = p_ma_vi;

    RETURN (v_trang_thai = 'HOAT_DONG');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN TOO_MANY_ROWS THEN
        RETURN FALSE;
END FN_KIEM_TRA_VI_HOAT_DONG;

-- 4. Ham kiem tra tong hop dieu kien chi tieu cua vi (Tra ve 1 neu hop le, nem ngoai le neu vi pham)
CREATE OR REPLACE FUNCTION FN_KIEM_TRA_DU_SO_DU(
    p_ma_vi           IN VARCHAR2,
    p_so_tien_can_chi IN NUMBER
) RETURN NUMBER IS
    v_so_du_kha_dung VI_DIEN_TU.SO_DU_KHA_DUNG%TYPE;
    v_han_muc_ngay   VI_DIEN_TU.HAN_MUC_NGAY%TYPE;
    v_trang_thai     VI_DIEN_TU.TRANG_THAI%TYPE;
    v_da_chi_hom_nay NUMBER(18, 2);
BEGIN
    IF p_so_tien_can_chi IS NULL OR p_so_tien_can_chi <= 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'So tien kiem tra phai lon hon 0.');
    END IF;

    BEGIN
        SELECT SO_DU_KHA_DUNG, HAN_MUC_NGAY, TRANG_THAI
          INTO v_so_du_kha_dung, v_han_muc_ngay, v_trang_thai
          FROM VI_DIEN_TU
         WHERE MA_VI = p_ma_vi;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Vi dien tu khong ton tai: ' || p_ma_vi);
    END;

    IF v_trang_thai <> 'HOAT_DONG' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Vi ' || p_ma_vi || ' dang o trang thai: ' || v_trang_thai);
    END IF;

    IF v_so_du_kha_dung < p_so_tien_can_chi THEN
        RAISE_APPLICATION_ERROR(-20001, 'So du kha dung (' || v_so_du_kha_dung || ') nho hon so tien can chi (' || p_so_tien_can_chi || ').');
    END IF;

    v_da_chi_hom_nay := FN_TONG_CHI_TRONG_NGAY(p_ma_vi, SYSDATE);
    IF (v_da_chi_hom_nay + p_so_tien_can_chi) > v_han_muc_ngay THEN
        RAISE_APPLICATION_ERROR(-20005, 'Vuot han muc ngay (' || v_han_muc_ngay || '). Da chi: ' || v_da_chi_hom_nay);
    END IF;

    RETURN 1;
END FN_KIEM_TRA_DU_SO_DU;

-- 5. Ham xep hang muc do su dung vi dua tren tong gia tri giao dich 30 ngay gan nhat (SQL-callable)
CREATE OR REPLACE FUNCTION FN_XEP_HANG_MUC_VI(
    p_ma_vi IN VARCHAR2
) RETURN NVARCHAR2 IS
    v_trang_thai VI_DIEN_TU.TRANG_THAI%TYPE;
    v_tong_30n   NUMBER(18, 2) := 0;
BEGIN
    SELECT TRANG_THAI
      INTO v_trang_thai
      FROM VI_DIEN_TU
     WHERE MA_VI = p_ma_vi;

    IF v_trang_thai <> 'HOAT_DONG' THEN
        RETURN N'BỊ KHOÁ / NGƯNG';
    END IF;

    SELECT NVL(SUM(SO_TIEN), 0)
      INTO v_tong_30n
      FROM GIAO_DICH
     WHERE (MA_VI_NGUON = p_ma_vi OR MA_VI_DICH = p_ma_vi)
       AND TRANG_THAI = 'THANH_CONG'
       AND NGAY_TAO >= SYSTIMESTAMP - NUMTODSINTERVAL(30, 'DAY');

    RETURN CASE
        WHEN v_tong_30n >= 50000000 THEN N'KIM CƯƠNG'
        WHEN v_tong_30n >= 15000000 THEN N'VÀNG'
        WHEN v_tong_30n >= 3000000  THEN N'BẠC'
        ELSE N'TIÊU CHUẨN'
    END;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN N'KHÔNG TỒN TẠI';
END FN_XEP_HANG_MUC_VI;
