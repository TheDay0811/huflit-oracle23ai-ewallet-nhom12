-- ============================================================================
-- 10_optimization_plans.sql
-- Phan tich Execution Plan truoc va sau toi uu cho 2 truy van trong tam
-- Oracle Database 23ai | Schema: EWALLET_APP
-- ============================================================================

DELETE FROM PLAN_TABLE
 WHERE STATEMENT_ID IN ('Q1_BEFORE', 'Q1_AFTER', 'Q2_BEFORE', 'Q2_AFTER');
COMMIT;

-- ============================================================================
-- TRUY VAN 1: Thong ke chi tieu va so giao dich thanh cong cua vi VI001 trong 30 ngay qua
-- ============================================================================

-- 1A. TRUOC TOI UU: Xoa index composite + dung ham TRUNC(NGAY_TAO) lam mat kha nang dung index
DROP INDEX IDX_GD_VI_NGUON_NGAY_TT;

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_BEFORE' FOR
SELECT COUNT(*) AS SO_GIAO_DICH,
       NVL(SUM(SO_TIEN), 0) AS TONG_CHI_TIEU
  FROM GIAO_DICH
 WHERE MA_VI_NGUON = 'VI001'
   AND TRANG_THAI  = 'THANH_CONG'
   AND TRUNC(NGAY_TAO) >= TRUNC(SYSDATE - 30);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_BEFORE', 'ALL'));

-- 1B. SAU TOI UU: Tao lai Composite Covering Index + viet lai dieu kien Sargable
CREATE INDEX IDX_GD_VI_NGUON_NGAY_TT
    ON GIAO_DICH (MA_VI_NGUON, TRANG_THAI, NGAY_TAO DESC, SO_TIEN);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'GIAO_DICH', cascade => TRUE);
END;

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_AFTER' FOR
SELECT COUNT(*) AS SO_GIAO_DICH,
       NVL(SUM(SO_TIEN), 0) AS TONG_CHI_TIEU
  FROM GIAO_DICH
 WHERE MA_VI_NGUON = 'VI001'
   AND TRANG_THAI  = 'THANH_CONG'
   AND NGAY_TAO   >= CAST(TRUNC(SYSDATE - 30) AS TIMESTAMP);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_AFTER', 'ALL'));

-- ============================================================================
-- TRUY VAN 2: Bao cao doi soat phat sinh No/Co theo tung vi va nhan vien trong 90 ngay
-- ============================================================================

-- 2A. TRUOC TOI UU: Xoa index + dung Correlated Subquery lap lai theo tung dong vi
DROP INDEX IDX_SC_VI_NGAY_LOAI;

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_BEFORE' FOR
SELECT v.MA_VI,
       nv.HO_TEN,
       (SELECT NVL(SUM(sc.SO_TIEN), 0)
          FROM CHI_TIET_SO_CAI sc
         WHERE sc.MA_VI = v.MA_VI
           AND sc.LOAI_BUT_TOAN = 'GHI_CO'
           AND TRUNC(sc.NGAY_GHI_SO) >= TRUNC(SYSDATE - 90)) AS TONG_GHI_CO,
       (SELECT NVL(SUM(sc.SO_TIEN), 0)
          FROM CHI_TIET_SO_CAI sc
         WHERE sc.MA_VI = v.MA_VI
           AND sc.LOAI_BUT_TOAN = 'GHI_NO'
           AND TRUNC(sc.NGAY_GHI_SO) >= TRUNC(SYSDATE - 90)) AS TONG_GHI_NO
  FROM VI_DIEN_TU v
  JOIN NHAN_VIEN nv ON v.MA_NV = nv.MA_NV
 ORDER BY v.MA_VI;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_BEFORE', 'ALL'));

-- 2B. SAU TOI UU: Covering Index + Gom nhom 1 luot (Conditional Aggregation) + Sargable Range
CREATE INDEX IDX_SC_VI_NGAY_LOAI
    ON CHI_TIET_SO_CAI (MA_VI, NGAY_GHI_SO DESC, LOAI_BUT_TOAN, SO_TIEN);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => 'CHI_TIET_SO_CAI', cascade => TRUE);
END;

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_AFTER' FOR
SELECT v.MA_VI,
       nv.HO_TEN,
       NVL(agg.TONG_GHI_CO, 0) AS TONG_GHI_CO,
       NVL(agg.TONG_GHI_NO, 0) AS TONG_GHI_NO
  FROM VI_DIEN_TU v
  JOIN NHAN_VIEN nv ON v.MA_NV = nv.MA_NV
  LEFT JOIN (
      SELECT sc.MA_VI,
             SUM(CASE WHEN sc.LOAI_BUT_TOAN = 'GHI_CO' THEN sc.SO_TIEN ELSE 0 END) AS TONG_GHI_CO,
             SUM(CASE WHEN sc.LOAI_BUT_TOAN = 'GHI_NO' THEN sc.SO_TIEN ELSE 0 END) AS TONG_GHI_NO
        FROM CHI_TIET_SO_CAI sc
       WHERE sc.NGAY_GHI_SO >= CAST(TRUNC(SYSDATE - 90) AS TIMESTAMP)
       GROUP BY sc.MA_VI
  ) agg ON v.MA_VI = agg.MA_VI
 ORDER BY v.MA_VI;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_AFTER', 'ALL'));
