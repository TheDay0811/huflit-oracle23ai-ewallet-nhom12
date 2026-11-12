import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

OUT_DIR = os.path.join(os.path.dirname(__file__), "assets")
os.makedirs(OUT_DIR, exist_ok=True)

plt.rcParams["font.family"] = "DejaVu Sans"


def draw_box(ax, x, y, w, h, title, lines=None, fc="#EFF6FF", ec="#1D4ED8",
             header_fc="#1D4ED8", header_tc="#FFFFFF", tc="#0F172A", fontsize=9.5, title_size=10):
    box = FancyBboxPatch(
        (x, y), w, h,
        boxstyle="round,pad=0.02,rounding_size=0.12",
        linewidth=1.5, edgecolor=ec, facecolor=fc, zorder=2
    )
    ax.add_patch(box)

    if lines:
        hh = min(0.42, h * 0.28)
        hbox = FancyBboxPatch(
            (x, y + h - hh), w, hh,
            boxstyle="round,pad=0.02,rounding_size=0.10",
            linewidth=0, facecolor=header_fc, zorder=3
        )
        ax.add_patch(hbox)
        ax.text(x + w / 2, y + h - hh / 2, title, ha="center", va="center",
                color=header_tc, fontsize=title_size, fontweight="bold", zorder=4)
        body_y = y + h - hh - 0.14
        step = (h - hh - 0.18) / max(len(lines), 1)
        for idx, line in enumerate(lines):
            ax.text(x + 0.12, body_y - idx * step, line, ha="left", va="top",
                    color=tc, fontsize=fontsize, zorder=4)
    else:
        ax.text(x + w / 2, y + h / 2, title, ha="center", va="center",
                color=tc, fontsize=title_size, fontweight="bold", zorder=4)


def draw_arrow(ax, x1, y1, x2, y2, label="", color="#334155", rad=0.0, lw=1.6, label_offset=(0, 0.15)):
    arr = FancyArrowPatch(
        (x1, y1), (x2, y2),
        connectionstyle=f"arc3,rad={rad}",
        arrowstyle="-|>,head_length=7,head_width=4.5",
        linewidth=lw, color=color, zorder=5
    )
    ax.add_patch(arr)
    if label:
        mx = (x1 + x2) / 2 + label_offset[0]
        my = (y1 + y2) / 2 + label_offset[1]
        ax.text(mx, my, label, ha="center", va="center", fontsize=8.5,
                color=color, fontweight="bold",
                bbox=dict(boxstyle="round,pad=0.18", fc="white", ec="none", alpha=0.9), zorder=6)


def make_architecture():
    fig, ax = plt.subplots(figsize=(11, 6.2), dpi=220)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 6.2)
    ax.axis("off")

    ax.text(5.5, 5.9, "KIẾN TRÚC TỔNG THỂ 3 TẦNG — HỆ THỐNG VÍ ĐIỆN TỬ NỘI BỘ",
            ha="center", va="center", fontsize=12.5, fontweight="bold", color="#0F172A")

    # Tier 1: Frontend
    draw_box(ax, 0.35, 1.0, 2.8, 4.3, "TẦNG 1: GIAO DIỆN WEB\n(HTML5 / CSS3 / Vanilla JS)",
             [
                 "• Dashboard Tổng quan & GD",
                 "• Quản lý Ví & Sổ cái kép",
                 "• Form Nạp / Rút / Chuyển tiền",
                 "• Thanh toán DV & Hoàn tiền",
                 "• Exception Lab (Mô phỏng lỗi)",
                 "• Đối soát Explicit Cursor"
             ],
             fc="#F8FAFC", ec="#0284C7", header_fc="#0284C7", fontsize=8.8, title_size=9.5)

    # Tier 2: Backend API
    draw_box(ax, 3.85, 1.0, 3.1, 4.3, "TẦNG 2: LỚP API BACKEND\n(Node.js + Express + oracledb)",
             [
                 "• REST Endpoints (/api/*)",
                 "• oracledb Thin Mode (Pool)",
                 "• Bind IN/OUT Variables",
                 "• Sinh Idempotency Key",
                 "• Test Race Condition song song",
                 "• Chuẩn hoá JSON HTTP 200/400"
             ],
             fc="#F0FDF4", ec="#059669", header_fc="#059669", fontsize=8.8, title_size=9.5)

    # Tier 3: Oracle 23ai Docker
    outer = FancyBboxPatch((7.6, 0.45), 3.1, 5.05, boxstyle="round,pad=0.02,rounding_size=0.14",
                           linewidth=1.8, edgecolor="#B91C1C", facecolor="#FEF2F2", zorder=1)
    ax.add_patch(outer)
    ax.text(9.15, 5.25, "TẦNG 3: ORACLE 23ai (DOCKER)\nContainer FREEPDB1 :1521",
            ha="center", va="center", fontsize=9.5, fontweight="bold", color="#991B1B")

    draw_box(ax, 7.82, 3.7, 2.66, 1.2, "Packages & Functions",
             ["PKG_QUAN_LY_VI | PKG_NGOAI_LE_VI", "5 Functions (SQL BOOLEAN, Tính phí)"],
             fc="#FFFFFF", ec="#DC2626", header_fc="#DC2626", fontsize=8.0, title_size=9.0)

    draw_box(ax, 7.82, 2.2, 2.66, 1.25, "Triggers & Concurrency",
             ["TRG_KIEM_TRA_SO_DU_VI", "Compound Trigger (ORA-04091)", "FOR UPDATE WAIT & SAVEPOINT"],
             fc="#FFFFFF", ec="#D97706", header_fc="#D97706", fontsize=8.0, title_size=9.0)

    draw_box(ax, 7.82, 0.68, 2.66, 1.25, "9 Bảng 3NF & Sổ cái",
             ["VI_DIEN_TU, GIAO_DICH", "CHI_TIET_SO_CAI (15.000+ GD)", "NHAT_KY_LOI (Autonomous Tx)"],
             fc="#FFFFFF", ec="#475569", header_fc="#475569", fontsize=8.0, title_size=9.0)

    # DBeaver box at bottom left
    draw_box(ax, 0.35, 0.2, 6.6, 0.58,
             "DBeaver Universal SQL Client — Kết nối trực tiếp JDBC :1521/FREEPDB1\n(Chạy DDL, PL/SQL, Kiểm thử 09_test_scenarios.sql & EXPLAIN PLAN)",
             fc="#FEF3C7", ec="#B45309", tc="#78350F", title_size=7.9)

    draw_arrow(ax, 3.18, 3.55, 3.82, 3.55, "HTTP JSON", color="#0284C7", label_offset=(0, 0.22))
    draw_arrow(ax, 3.82, 2.75, 3.18, 2.75, "Response", color="#059669", label_offset=(0, -0.22))
    draw_arrow(ax, 6.98, 3.55, 7.60, 3.55, "TCP :1521", color="#DC2626", label_offset=(0, 0.22))
    draw_arrow(ax, 7.60, 2.75, 6.98, 2.75, "OUT Binds", color="#B91C1C", label_offset=(0, -0.22))
    draw_arrow(ax, 6.98, 0.49, 7.60, 1.15, "JDBC", color="#B45309", label_offset=(-0.05, 0.24))

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "fig1_architecture.png"), dpi=220, bbox_inches="tight")
    plt.close()


def make_erd():
    fig, ax = plt.subplots(figsize=(13.5, 8.6), dpi=220)
    ax.set_xlim(0, 13.5)
    ax.set_ylim(0, 8.6)
    ax.axis("off")

    ax.text(6.75, 8.32, "SƠ ĐỒ THỰC THỂ KẾT HỢP (ERD) — CHUẨN HOÁ 3NF (9 BẢNG)",
            ha="center", va="center", fontsize=13, fontweight="bold", color="#0F172A")

    # Row 1 (top)
    draw_box(ax, 0.3, 6.2, 2.8, 1.8, "PHONG_BAN",
             ["PK  MA_PB (VARCHAR2)", "    TEN_PB (NVARCHAR2)", "    HAN_MUC_CHI_THANG", "    TRANG_THAI", "    NGAY_TAO"],
             fc="#EFF6FF", ec="#1D4ED8", header_fc="#1D4ED8", fontsize=8.2)

    draw_box(ax, 3.8, 6.0, 3.0, 2.0, "NHAN_VIEN",
             ["PK  MA_NV (VARCHAR2)", "FK  MA_PB → PHONG_BAN", "    HO_TEN (NVARCHAR2)", "UQ  EMAIL", "    SO_DIEN_THOAI, CHUC_VU", "    TRANG_THAI, NGAY_VAO_LAM"],
             fc="#EFF6FF", ec="#1D4ED8", header_fc="#1D4ED8", fontsize=8.2)

    draw_box(ax, 7.45, 5.75, 3.1, 2.25, "VI_DIEN_TU",
             ["PK  MA_VI (VARCHAR2)", "UQ  SO_TAI_KHOAN", "FK  MA_NV → NHAN_VIEN", "    LOAI_VI, TRANG_THAI", "    SO_DU, SO_DU_KHA_DUNG", "    HAN_MUC_NGAY, VERSION_LOCK", "    NGAY_MO, NGAY_CAP_NHAT"],
             fc="#ECFDF5", ec="#059669", header_fc="#059669", fontsize=8.2)

    draw_box(ax, 11.3, 6.1, 2.05, 1.85, "DOI_TAC_DICH_VU",
             ["PK  MA_DOI_TAC", "FK  MA_VI_NHAN → VI", "    TEN_DOI_TAC", "    LOAI_DICH_VU", "    TRANG_THAI"],
             fc="#ECFDF5", ec="#059669", header_fc="#059669", fontsize=8.2)

    # Row 2 (middle)
    draw_box(ax, 0.3, 3.15, 2.9, 2.0, "LOAI_GIAO_DICH",
             ["PK  MA_LOAI_GD", "    TEN_LOAI (NVARCHAR2)", "    PHI_CO_DINH", "    TY_LE_PHI", "    PHI_TOI_DA", "    CO_TINH_HAN_MUC"],
             fc="#FFF7ED", ec="#C2410C", header_fc="#C2410C", fontsize=8.2)

    draw_box(ax, 4.1, 2.65, 3.7, 2.65, "GIAO_DICH",
             ["PK  MA_GD (NUMBER)", "UQ  MA_THAM_CHIEU (Idempotency)", "FK  MA_VI_NGUON → VI_DIEN_TU",
              "FK  MA_VI_DICH → VI_DIEN_TU", "FK  MA_LOAI_GD → LOAI_GIAO_DICH",
              "FK  MA_GD_GOC → GIAO_DICH", "    SO_TIEN, PHI_GD, TONG_TIEN", "    TRANG_THAI, NGAY_TAO"],
             fc="#FEF2F2", ec="#DC2626", header_fc="#DC2626", fontsize=8.2)

    draw_box(ax, 8.8, 3.05, 4.4, 2.15, "NHAT_KY_TRANG_THAI_VI",
             ["PK  MA_LOG_TT (NUMBER)", "FK  MA_VI → VI_DIEN_TU", "    TRANG_THAI_CU, TRANG_THAI_MOI",
              "    LY_DO (NVARCHAR2)", "    NGUOI_THAY_DOI, THOI_GIAN", "    (Ghi tự động bởi Trigger)"],
             fc="#FEFCE8", ec="#CA8A04", header_fc="#CA8A04", fontsize=8.2)

    # Row 3 (bottom)
    draw_box(ax, 3.6, 0.25, 4.5, 1.95, "CHI_TIET_SO_CAI (Sổ cái kép)",
             ["PK  MA_BUT_TOAN (NUMBER)", "FK  MA_GD → GIAO_DICH", "FK  MA_VI → VI_DIEN_TU",
              "    LOAI_BUT_TOAN (GHI_NO / GHI_CO)", "    SO_TIEN, SO_DU_TRUOC, SO_DU_SAU", "    MO_TA, NGAY_GHI_SO"],
             fc="#F5F3FF", ec="#7C3AED", header_fc="#7C3AED", fontsize=8.2)

    draw_box(ax, 8.8, 0.25, 4.4, 2.05, "NHAT_KY_LOI_GIAO_DICH",
             ["PK  MA_LOG (NUMBER)", "    MA_THAM_CHIEU, TEN_MODULE", "    MA_LOI_ORACLE, MA_LOI_NGHIEP_VU",
              "    THONG_DIEP_LOI, DU_LIEU_DAU_VAO", "    STACK_TRACE, NGUOI_THUC_HIEN", "    (PRAGMA AUTONOMOUS_TRANSACTION)"],
             fc="#F1F5F9", ec="#475569", header_fc="#475569", fontsize=8.2)

    # Relationships
    draw_arrow(ax, 3.12, 7.1, 3.78, 7.1, "1 : N", color="#1D4ED8", label_offset=(0, 0.2))
    draw_arrow(ax, 6.82, 7.0, 7.43, 7.0, "1 : N", color="#059669", label_offset=(0, 0.2))
    draw_arrow(ax, 10.57, 7.0, 11.28, 7.0, "1 : N", color="#059669", label_offset=(0, 0.22))
    draw_arrow(ax, 3.22, 4.1, 4.08, 4.1, "1 : N", color="#C2410C", label_offset=(0, 0.2))
    draw_arrow(ax, 8.1, 5.72, 6.5, 5.32, "1 : N (Nguồn/Đích)", color="#DC2626", label_offset=(0.55, 0.15))
    draw_arrow(ax, 10.1, 5.72, 10.1, 5.22, "1 : N", color="#CA8A04", label_offset=(0.35, 0))
    draw_arrow(ax, 5.85, 2.63, 5.85, 2.22, "1 : N", color="#7C3AED", label_offset=(0.35, 0))
    draw_arrow(ax, 8.45, 5.72, 7.85, 2.22, "1 : N", color="#7C3AED", rad=-0.08, label_offset=(0.28, -0.35))

    # Self-ref arrow on GIAO_DICH (MA_GD_GOC)
    draw_arrow(ax, 4.08, 3.3, 4.08, 2.85, "Hoàn tiền", color="#991B1B", rad=0.7, label_offset=(-0.55, 0))

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "fig2_erd.png"), dpi=220, bbox_inches="tight")
    plt.close()


def make_exception_flow():
    fig, ax = plt.subplots(figsize=(11, 7.2), dpi=220)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 7.2)
    ax.axis("off")

    ax.text(5.5, 6.92, "LUỒNG XỬ LÝ GIAO DỊCH & CƠ CHẾ EXCEPTION HANDLING (SP_CHUYEN_TIEN)",
            ha="center", va="center", fontsize=12, fontweight="bold", color="#0F172A")

    draw_box(ax, 0.5, 5.8, 3.3, 0.72, "1. Nhận yêu cầu + SAVEPOINT",
             ["SAVEPOINT sp_chuyen_tien;"], fc="#EFF6FF", ec="#1D4ED8", header_fc="#1D4ED8", fontsize=8.5)

    draw_box(ax, 0.5, 4.55, 3.3, 0.95, "2. Kiểm tra đầu vào & Idempotency",
             ["• Số tiền <= 0 → e_so_tien_khong_hop_le (-20006)",
              "• Nguồn = Đích → e_chuyen_cung_vi (-20007)",
              "• Trùng MA_THAM_CHIEU → -20002"],
             fc="#EFF6FF", ec="#1D4ED8", header_fc="#1D4ED8", fontsize=8.0)

    draw_box(ax, 0.5, 3.25, 3.3, 1.0, "3. Khoá ví thứ tự tăng dần MA_VI",
             ["• SELECT ... FOR UPDATE WAIT 2",
              "• Không có ví → NO_DATA_FOUND → -20004",
              "• Đụng độ khoá → ORA-00054/30006 → -20010"],
             fc="#ECFDF5", ec="#059669", header_fc="#059669", fontsize=8.0)

    draw_box(ax, 0.5, 1.9, 3.3, 1.05, "4. Kiểm tra Trạng thái, Số dư, Hạn mức",
             ["• Ví nguồn/đích khoá → -20003 / -20008",
              "• Số dư < Tiền + Phí → -20001",
              "• Vượt hạn mức ngày → -20005"],
             fc="#ECFDF5", ec="#059669", header_fc="#059669", fontsize=8.0)

    draw_box(ax, 0.5, 0.35, 3.3, 1.2, "5. Ghi GIAO_DICH, Sổ cái & COMMIT",
             ["• INSERT GIAO_DICH (UQ_GD_THAM_CHIEU)",
              "• UPDATE VI_DIEN_TU + CHI_TIET_SO_CAI",
              "• COMMIT & Trả p_ma_loi = 0"],
             fc="#DCFCE7", ec="#15803D", header_fc="#15803D", fontsize=8.0)

    # Right branch: Exception handler
    draw_box(ax, 5.3, 3.55, 5.2, 2.15, "KHỐI EXCEPTION HANDLER TRONG PL/SQL",
             ["• Bắt User-Defined Exceptions (-20001 .. -20010)",
              "• Bắt Predefined Exceptions: DUP_VAL_ON_INDEX, NO_DATA_FOUND,",
              "  VALUE_ERROR, ORA-00054 (NOWAIT), ORA-30006 (WAIT), OTHERS",
              "• Bước A: ROLLBACK TO sp_chuyen_tien; (Huỷ mọi thay đổi dở dang)",
              "• Bước B: Gọi PKG_NGOAI_LE_VI.SP_GHI_NHAT_KY_LOI(...)"],
             fc="#FEF2F2", ec="#DC2626", header_fc="#DC2626", fontsize=8.2)

    draw_box(ax, 5.3, 1.75, 5.2, 1.35, "PRAGMA AUTONOMOUS_TRANSACTION",
             ["• Mở giao dịch con độc lập với giao dịch chính đã ROLLBACK",
              "• INSERT vào NHAT_KY_LOI_GIAO_DICH + FORMAT_ERROR_BACKTRACE",
              "• COMMIT riêng bảng log → Luôn lưu vết được sự cố để audit"],
             fc="#FFF7ED", ec="#C2410C", header_fc="#C2410C", fontsize=8.2)

    draw_box(ax, 5.3, 0.35, 5.2, 1.0, "Trả kết quả về API / Caller",
             ["• Xuất p_ma_loi (-20001..-20010), p_ma_loi_nghiep_vu, p_thong_bao",
              "• Tuỳ chọn RAISE lại ngoại lệ nếu p_nem_ngoai_le = 1"],
             fc="#F1F5F9", ec="#475569", header_fc="#475569", fontsize=8.2)

    draw_arrow(ax, 2.15, 5.78, 2.15, 5.52, "", color="#1D4ED8")
    draw_arrow(ax, 2.15, 4.53, 2.15, 4.27, "Hợp lệ", color="#059669", label_offset=(0.45, 0))
    draw_arrow(ax, 2.15, 3.23, 2.15, 2.97, "Đã khoá", color="#059669", label_offset=(0.48, 0))
    draw_arrow(ax, 2.15, 1.88, 2.15, 1.57, "Đạt ĐK", color="#15803D", label_offset=(0.45, 0))

    draw_arrow(ax, 3.82, 4.95, 5.28, 4.95, "RAISE", color="#DC2626", label_offset=(0, 0.18))
    draw_arrow(ax, 3.82, 3.75, 5.28, 4.35, "RAISE", color="#DC2626", label_offset=(0, 0.18))
    draw_arrow(ax, 3.82, 2.45, 5.28, 3.9, "RAISE", color="#DC2626", label_offset=(0.05, 0.2))
    draw_arrow(ax, 3.82, 1.0, 5.28, 3.65, "DUP_VAL", color="#DC2626", label_offset=(0.15, 0.25))

    draw_arrow(ax, 7.9, 3.53, 7.9, 3.12, "Ghi log độc lập", color="#C2410C", label_offset=(0.85, 0))
    draw_arrow(ax, 7.9, 1.73, 7.9, 1.37, "", color="#475569")

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "fig3_exception_flow.png"), dpi=220, bbox_inches="tight")
    plt.close()


def make_compound_trigger():
    fig, ax = plt.subplots(figsize=(10.5, 4.8), dpi=220)
    ax.set_xlim(0, 10.5)
    ax.set_ylim(0, 4.8)
    ax.axis("off")

    ax.text(5.25, 4.5, "CƠ CHẾ COMPOUND TRIGGER TRÁNH LỖI MUTATING TABLE (ORA-04091)",
            ha="center", va="center", fontsize=11.5, fontweight="bold", color="#0F172A")

    draw_box(ax, 0.3, 2.55, 4.6, 1.55, "CÁCH TRUYỀN THỐNG (GÂY LỖI ORA-04091)",
             ["• Trigger BEFORE/AFTER INSERT ... FOR EACH ROW",
              "• Truy vấn SELECT SUM(...) FROM GIAO_DICH ngay bên trong",
              "• Bảng GIAO_DICH đang bị biến đổi (Mutating)",
              "• Oracle ném lỗi ORA-04091 và huỷ lệnh!"],
             fc="#FEF2F2", ec="#DC2626", header_fc="#DC2626", fontsize=8.3)

    draw_box(ax, 5.3, 0.4, 4.9, 3.7, "COMPOUND TRIGGER (TRG_KIEM_SOAT_GD_BATTUONG)",
             ["1. BEFORE STATEMENT:",
              "   Xoá bộ sưu tập bộ nhớ g_vi_ngay.DELETE;",
              "2. AFTER EACH ROW (Không truy vấn bảng GIAO_DICH):",
              "   Thu thập mã ví nguồn & ngày vào mảng g_vi_ngay(:NEW.MA_VI_NGUON)",
              "3. AFTER STATEMENT (Bảng GIAO_DICH đã hết mutating):",
              "   Duyệt từng ví trong g_vi_ngay, tính SUM(TONG_TIEN) trong ngày",
              "   Nếu > HAN_MUC_NGAY → RAISE_APPLICATION_ERROR(-20005)"],
             fc="#ECFDF5", ec="#059669", header_fc="#059669", fontsize=8.2)

    draw_box(ax, 0.3, 0.4, 4.6, 1.7, "LỢI ÍCH KIẾN TRÚC",
             ["• Bảo vệ toàn vẹn hạn mức ngay cả khi INSERT trực tiếp bằng SQL",
              "• An toàn cho cả lệnh INSERT đơn lẻ lẫn INSERT nhiều dòng",
              "• Giảm số lần truy vấn kiểm tra xuống 1 lần / mỗi ví bị ảnh hưởng"],
             fc="#EFF6FF", ec="#1D4ED8", header_fc="#1D4ED8", fontsize=8.3)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "fig4_compound_trigger.png"), dpi=220, bbox_inches="tight")
    plt.close()


def make_optimization_chart():
    fig, axes = plt.subplots(1, 2, figsize=(11.2, 4.7), dpi=220)

    # Chart 1: CBO Cost Comparison (Real Oracle 23ai 23.7.0.0 DBMS_XPLAN measurements)
    queries = ["Truy vấn 1\n(Thống kê GD 30 ngày)", "Truy vấn 2\n(Đối soát Sổ cái 90 ngày)"]
    before_cost = [102, 282]
    after_cost = [5, 63]

    x = [0, 1]
    w = 0.32
    b1 = axes[0].bar([i - w / 2 for i in x], before_cost, width=w, label="Trước tối ưu (Full Table Scan)", color="#EF4444")
    b2 = axes[0].bar([i + w / 2 for i in x], after_cost, width=w, label="Sau tối ưu (Covering Index)", color="#10B981")

    axes[0].set_title("So sánh Optimizer Cost (CBO)", fontsize=11, fontweight="bold")
    axes[0].set_xticks(x)
    axes[0].set_xticklabels(queries, fontsize=9)
    axes[0].set_ylabel("CBO Estimated Cost (càng thấp càng tốt)", fontsize=9)
    axes[0].legend(fontsize=8.5)
    axes[0].grid(axis="y", linestyle="--", alpha=0.4)
    for bar in b1:
        h = bar.get_height()
        axes[0].text(bar.get_x() + bar.get_width() / 2, h + 6, f"{h}", ha="center", va="bottom", fontsize=9, fontweight="bold")
    for idx, bar in enumerate(b2):
        h = bar.get_height()
        pct = (1 - after_cost[idx] / before_cost[idx]) * 100
        axes[0].text(bar.get_x() + bar.get_width() / 2, h + 6, f"{h}\n(-{pct:.1f}%)", ha="center", va="bottom", fontsize=8.5, fontweight="bold", color="#047857")
    axes[0].set_ylim(0, 340)

    # Chart 2: Logical Reads (Real Buffers from DBMS_XPLAN.DISPLAY_CURSOR ALLSTATS LAST)
    before_gets = [373, 924]
    after_gets = [5, 195]

    b3 = axes[1].bar([i - w / 2 for i in x], before_gets, width=w, label="Trước tối ưu", color="#F97316")
    b4 = axes[1].bar([i + w / 2 for i in x], after_gets, width=w, label="Sau tối ưu", color="#2563EB")

    axes[1].set_title("So sánh Khối đọc hợp lý (Buffers / Consistent Gets)", fontsize=11, fontweight="bold")
    axes[1].set_xticks(x)
    axes[1].set_xticklabels(queries, fontsize=9)
    axes[1].set_ylabel("Buffers (Logical Block Reads)", fontsize=9)
    axes[1].legend(fontsize=8.5)
    axes[1].grid(axis="y", linestyle="--", alpha=0.4)
    for bar in b3:
        h = bar.get_height()
        axes[1].text(bar.get_x() + bar.get_width() / 2, h + 18, f"{h}", ha="center", va="bottom", fontsize=9, fontweight="bold")
    for idx, bar in enumerate(b4):
        h = bar.get_height()
        pct = (1 - after_gets[idx] / before_gets[idx]) * 100
        axes[1].text(bar.get_x() + bar.get_width() / 2, h + 18, f"{h}\n(-{pct:.1f}%)", ha="center", va="bottom", fontsize=8.5, fontweight="bold", color="#1D4ED8")
    axes[1].set_ylim(0, 1100)

    plt.suptitle("KẾT QUẢ ĐO THỰC TẾ TRÊN ORACLE 23ai (23.7.0.0) — 15.000+ GD / 30.000+ BÚT TOÁN",
                 fontsize=11.0, fontweight="bold", y=1.02)
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, "fig5_exec_plan_comparison.png"), dpi=220, bbox_inches="tight")
    plt.close()


if __name__ == "__main__":
    make_architecture()
    make_erd()
    make_exception_flow()
    make_compound_trigger()
    make_optimization_chart()
    print("Generated 5 diagrams successfully in", OUT_DIR)
