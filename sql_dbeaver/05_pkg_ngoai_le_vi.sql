-- ============================================================================
-- 05_pkg_ngoai_le_vi.sql
-- Package trung tam dinh nghia User-Defined Exceptions (PRAGMA EXCEPTION_INIT)
-- va ghi nhat ky loi doc lap bang PRAGMA AUTONOMOUS_TRANSACTION
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_NGOAI_LE_VI AS
    -- Khai bao User-Defined Exceptions va anh xa ma loi Oracle (-20001 .. -20010)
    e_so_du_khong_du        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_so_du_khong_du, -20001);

    e_giao_dich_trung_lap   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_giao_dich_trung_lap, -20002);

    e_vi_bi_khoa            EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vi_bi_khoa, -20003);

    e_vi_khong_ton_tai      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vi_khong_ton_tai, -20004);

    e_vuot_han_muc_ngay     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vuot_han_muc_ngay, -20005);

    e_so_tien_khong_hop_le  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_so_tien_khong_hop_le, -20006);

    e_chuyen_cung_vi        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_chuyen_cung_vi, -20007);

    e_vi_dich_bi_khoa       EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vi_dich_bi_khoa, -20008);

    e_khong_the_hoan_tien   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_khong_the_hoan_tien, -20009);

    e_khoa_dong_thoi        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_khoa_dong_thoi, -20010);

    -- Anh xa loi khoa dong thoi he thong Oracle (ORA-00054 NOWAIT va ORA-30006 WAIT timeout)
    e_ora_resource_busy     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ora_resource_busy, -54);

    e_ora_wait_timeout      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ora_wait_timeout, -30006);

    -- Hang so ma loi nghiep vu chuan hoa cho tang API
    C_ERR_SO_DU_KHONG_DU      CONSTANT VARCHAR2(40) := 'ERR_INSUFFICIENT_BALANCE';
    C_ERR_GIAO_DICH_TRUNG     CONSTANT VARCHAR2(40) := 'ERR_DUPLICATE_TRANSACTION';
    C_ERR_VI_BI_KHOA          CONSTANT VARCHAR2(40) := 'ERR_WALLET_LOCKED';
    C_ERR_VI_KHONG_TON_TAI    CONSTANT VARCHAR2(40) := 'ERR_WALLET_NOT_FOUND';
    C_ERR_VUOT_HAN_MUC        CONSTANT VARCHAR2(40) := 'ERR_DAILY_LIMIT_EXCEEDED';
    C_ERR_SO_TIEN_KHONG_HOPLE CONSTANT VARCHAR2(40) := 'ERR_INVALID_AMOUNT';
    C_ERR_CHUYEN_CUNG_VI      CONSTANT VARCHAR2(40) := 'ERR_SAME_WALLET_TRANSFER';
    C_ERR_VI_DICH_BI_KHOA     CONSTANT VARCHAR2(40) := 'ERR_DEST_WALLET_LOCKED';
    C_ERR_KHONG_THE_HOAN_TIEN CONSTANT VARCHAR2(40) := 'ERR_REFUND_NOT_ALLOWED';
    C_ERR_KHOA_DONG_THOI      CONSTANT VARCHAR2(40) := 'ERR_CONCURRENT_LOCK';
    C_ERR_HE_THONG            CONSTANT VARCHAR2(40) := 'ERR_SYSTEM_INTERNAL';

    -- Ghi nhat ky loi trong giao dich doc lap (ton tai ngay ca khi giao dich chinh ROLLBACK)
    PROCEDURE SP_GHI_NHAT_KY_LOI(
        p_ma_tham_chieu   IN VARCHAR2,
        p_ten_module      IN VARCHAR2,
        p_ma_loi_oracle   IN NUMBER,
        p_ma_loi_nghiep_vu IN VARCHAR2,
        p_thong_diep_loi  IN NVARCHAR2,
        p_du_lieu_dau_vao IN NVARCHAR2 DEFAULT NULL,
        p_stack_trace     IN VARCHAR2  DEFAULT NULL,
        p_nguoi_thuc_hien IN VARCHAR2  DEFAULT 'SYSTEM'
    );

    -- Ham anh xa ma loi sang thong diep than thien (ho tro truy van SQL)
    FUNCTION FN_LAY_THONG_DIEP_LOI(
        p_ma_loi_oracle IN NUMBER
    ) RETURN NVARCHAR2;
END PKG_NGOAI_LE_VI;

CREATE OR REPLACE PACKAGE BODY PKG_NGOAI_LE_VI AS

    PROCEDURE SP_GHI_NHAT_KY_LOI(
        p_ma_tham_chieu   IN VARCHAR2,
        p_ten_module      IN VARCHAR2,
        p_ma_loi_oracle   IN NUMBER,
        p_ma_loi_nghiep_vu IN VARCHAR2,
        p_thong_diep_loi  IN NVARCHAR2,
        p_du_lieu_dau_vao IN NVARCHAR2 DEFAULT NULL,
        p_stack_trace     IN VARCHAR2  DEFAULT NULL,
        p_nguoi_thuc_hien IN VARCHAR2  DEFAULT 'SYSTEM'
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO NHAT_KY_LOI_GIAO_DICH (
            MA_LOG, MA_THAM_CHIEU, TEN_MODULE, MA_LOI_ORACLE,
            MA_LOI_NGHIEP_VU, THONG_DIEP_LOI, DU_LIEU_DAU_VAO,
            STACK_TRACE, NGUOI_THUC_HIEN, THOI_GIAN_LOI
        ) VALUES (
            SEQ_LOG_LOI.NEXTVAL,
            SUBSTR(p_ma_tham_chieu, 1, 80),
            SUBSTR(NVL(p_ten_module, 'UNKNOWN'), 1, 100),
            NVL(p_ma_loi_oracle, -20000),
            SUBSTR(NVL(p_ma_loi_nghiep_vu, C_ERR_HE_THONG), 1, 50),
            SUBSTR(NVL(p_thong_diep_loi, N'Lỗi không xác định'), 1, 500),
            SUBSTR(p_du_lieu_dau_vao, 1, 1000),
            SUBSTR(p_stack_trace, 1, 2000),
            SUBSTR(NVL(p_nguoi_thuc_hien, 'SYSTEM'), 1, 50),
            SYSTIMESTAMP
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END SP_GHI_NHAT_KY_LOI;

    FUNCTION FN_LAY_THONG_DIEP_LOI(
        p_ma_loi_oracle IN NUMBER
    ) RETURN NVARCHAR2 IS
    BEGIN
        RETURN CASE p_ma_loi_oracle
            WHEN -20001 THEN N'Số dư khả dụng trong ví không đủ để thực hiện giao dịch.'
            WHEN -20002 THEN N'Giao dịch trùng lặp: Mã tham chiếu (Idempotency Key) đã được xử lý trước đó.'
            WHEN -20003 THEN N'Ví nguồn đang bị tạm khoá hoặc đã đóng vĩnh viễn.'
            WHEN -20004 THEN N'Không tìm thấy ví điện tử tương ứng trong hệ thống.'
            WHEN -20005 THEN N'Tổng số tiền giao dịch vượt quá hạn mức chi tiêu trong ngày của ví.'
            WHEN -20006 THEN N'Số tiền giao dịch không hợp lệ (phải lớn hơn 0).'
            WHEN -20007 THEN N'Không thể thực hiện chuyển tiền đến chính ví nguồn.'
            WHEN -20008 THEN N'Ví người nhận đang bị tạm khoá hoặc đóng, không thể nhận tiền.'
            WHEN -20009 THEN N'Giao dịch gốc không tồn tại hoặc không đủ điều kiện hoàn tiền.'
            WHEN -20010 THEN N'Ví đang được xử lý bởi một giao dịch đồng thời khác, vui lòng thử lại.'
            WHEN -1     THEN N'Vi phạm ràng buộc duy nhất (DUP_VAL_ON_INDEX) - phát hiện giao dịch trùng.'
            WHEN 100    THEN N'Không tìm thấy dữ liệu phù hợp (NO_DATA_FOUND).'
            ELSE N'Lỗi hệ thống Oracle (' || TO_CHAR(p_ma_loi_oracle) || N').'
        END;
    END FN_LAY_THONG_DIEP_LOI;

END PKG_NGOAI_LE_VI;
