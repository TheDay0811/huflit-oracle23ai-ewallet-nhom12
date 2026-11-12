-- ============================================================================
-- 03_sequences_indexes.sql
-- Tao Sequences va Indexes phuc vu hieu nang truy van va toi uu hoa
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

-- Sequences
CREATE SEQUENCE SEQ_GIAO_DICH      START WITH 100001 INCREMENT BY 1 CACHE 50 NOCYCLE;
CREATE SEQUENCE SEQ_SO_CAI         START WITH 200001 INCREMENT BY 1 CACHE 50 NOCYCLE;
CREATE SEQUENCE SEQ_LOG_LOI        START WITH 1      INCREMENT BY 1 CACHE 20 NOCYCLE;
CREATE SEQUENCE SEQ_LOG_TRANG_THAI START WITH 1      INCREMENT BY 1 CACHE 20 NOCYCLE;

-- Indexes khoa ngoai va tra cuu thong thuong
CREATE INDEX IDX_NV_PHONGBAN      ON NHAN_VIEN (MA_PB);
CREATE INDEX IDX_VI_TRANG_THAI    ON VI_DIEN_TU (TRANG_THAI);
CREATE INDEX IDX_SC_GIAO_DICH     ON CHI_TIET_SO_CAI (MA_GD);
CREATE INDEX IDX_LOG_TT_VI        ON NHAT_KY_TRANG_THAI_VI (MA_VI, THOI_GIAN DESC);
CREATE INDEX IDX_LOG_LOI_TIME     ON NHAT_KY_LOI_GIAO_DICH (THOI_GIAN_LOI DESC, MA_LOI_NGHIEP_VU);

-- Composite Indexes toi uu hoa 2 truy van trong tam (Phan tich o Buoc 10)
-- Index 1: Toi uu tra cuu lich su giao dich va tong chi trong ngay theo vi + trang thai + thoi gian
CREATE INDEX IDX_GD_VI_NGUON_NGAY_TT
    ON GIAO_DICH (MA_VI_NGUON, TRANG_THAI, NGAY_TAO DESC, SO_TIEN);

CREATE INDEX IDX_GD_VI_DICH_NGAY_TT
    ON GIAO_DICH (MA_VI_DICH, TRANG_THAI, NGAY_TAO DESC);

-- Index 2: Toi uu doi soat so cai ke toan theo vi, loai but toan va ngay ghi so
CREATE INDEX IDX_SC_VI_NGAY_LOAI
    ON CHI_TIET_SO_CAI (MA_VI, NGAY_GHI_SO DESC, LOAI_BUT_TOAN, SO_TIEN);
