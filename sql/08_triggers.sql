-- ============================================================================
-- 08_triggers.sql
-- 3 Triggers bao ve toan ven so du, ghi nhat ky trang thai va Compound Trigger
-- kiem soat han muc ngay tranh loi Mutating Table (ORA-04091)
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

-- 1. Trigger BEFORE UPDATE: Bao ve toan ven so du, ngan chan sua so du vi dang bi khoa
CREATE OR REPLACE TRIGGER TRG_KIEM_TRA_SO_DU_VI
BEFORE UPDATE OF SO_DU, SO_DU_KHA_DUNG ON VI_DIEN_TU
FOR EACH ROW
BEGIN
    IF :OLD.TRANG_THAI IN ('TAM_KHOA', 'DONG_VINH_VIEN') THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Khong the thay doi so du khi vi ' || :OLD.MA_VI || ' dang o trang thai ' || :OLD.TRANG_THAI
        );
    END IF;

    IF :NEW.SO_DU < 0 OR :NEW.SO_DU_KHA_DUNG < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'So du vi ' || :OLD.MA_VI || ' khong duoc phep nho hon 0.'
        );
    END IF;

    :NEW.NGAY_CAP_NHAT := SYSTIMESTAMP;
END;
/

-- 2. Trigger AFTER UPDATE: Tu dong ghi nhan lich su thay doi trang thai vi
CREATE OR REPLACE TRIGGER TRG_NHAT_KY_TRANG_THAI_VI
AFTER UPDATE OF TRANG_THAI ON VI_DIEN_TU
FOR EACH ROW
WHEN (OLD.TRANG_THAI <> NEW.TRANG_THAI)
BEGIN
    INSERT INTO NHAT_KY_TRANG_THAI_VI (
        MA_LOG_TT, MA_VI, TRANG_THAI_CU, TRANG_THAI_MOI, LY_DO, NGUOI_THAY_DOI, THOI_GIAN
    ) VALUES (
        SEQ_LOG_TRANG_THAI.NEXTVAL,
        :NEW.MA_VI,
        :OLD.TRANG_THAI,
        :NEW.TRANG_THAI,
        NVL(PKG_QUAN_LY_VI.g_ly_do_doi_tt, N'Thay đổi trạng thái trực tiếp qua SQL'),
        NVL(PKG_QUAN_LY_VI.g_nguoi_thuc_hien, USER),
        SYSTIMESTAMP
    );
END;
/

-- 3. Compound Trigger: Kiem soat tong chi trong ngay tren GIAO_DICH ma khong gay loi Mutating Table (ORA-04091)
CREATE OR REPLACE TRIGGER TRG_KIEM_SOAT_GD_BATTUONG
FOR INSERT ON GIAO_DICH
COMPOUND TRIGGER
    TYPE t_vi_set IS TABLE OF DATE INDEX BY VARCHAR2(20);
    g_vi_ngay t_vi_set;

    BEFORE STATEMENT IS
    BEGIN
        g_vi_ngay.DELETE;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF :NEW.MA_VI_NGUON IS NOT NULL
           AND :NEW.TRANG_THAI IN ('CHO_XU_LY', 'THANH_CONG')
           AND :NEW.MA_LOAI_GD IN ('RUT_TIEN', 'CHUYEN_NOI_BO', 'THANH_TOAN_DV') THEN
            g_vi_ngay(:NEW.MA_VI_NGUON) := TRUNC(CAST(:NEW.NGAY_TAO AS DATE));
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_ma_vi          VARCHAR2(20);
        v_ngay           DATE;
        v_tong_trong_ngay NUMBER(18, 2);
        v_han_muc_ngay    NUMBER(18, 2);
    BEGIN
        v_ma_vi := g_vi_ngay.FIRST;
        WHILE v_ma_vi IS NOT NULL LOOP
            v_ngay := g_vi_ngay(v_ma_vi);

            SELECT HAN_MUC_NGAY
              INTO v_han_muc_ngay
              FROM VI_DIEN_TU
             WHERE MA_VI = v_ma_vi;

            SELECT NVL(SUM(gd.TONG_TIEN), 0)
              INTO v_tong_trong_ngay
              FROM GIAO_DICH gd
              JOIN LOAI_GIAO_DICH lgd ON gd.MA_LOAI_GD = lgd.MA_LOAI_GD
             WHERE gd.MA_VI_NGUON = v_ma_vi
               AND gd.TRANG_THAI IN ('CHO_XU_LY', 'THANH_CONG')
               AND lgd.CO_TINH_HAN_MUC = 1
               AND gd.NGAY_TAO >= CAST(v_ngay AS TIMESTAMP)
               AND gd.NGAY_TAO <  CAST(v_ngay + 1 AS TIMESTAMP);

            IF v_tong_trong_ngay > v_han_muc_ngay THEN
                RAISE_APPLICATION_ERROR(
                    -20005,
                    'Compound Trigger: Vi ' || v_ma_vi || ' vuot han muc ngay (' ||
                    v_tong_trong_ngay || ' > ' || v_han_muc_ngay || ').'
                );
            END IF;

            v_ma_vi := g_vi_ngay.NEXT(v_ma_vi);
        END LOOP;
    END AFTER STATEMENT;
END TRG_KIEM_SOAT_GD_BATTUONG;
/
