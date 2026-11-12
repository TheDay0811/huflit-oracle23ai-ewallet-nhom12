# ĐỒ ÁN CUỐI KỲ: HỆ THỐNG THANH TOÁN VÍ ĐIỆN TỬ NỘI BỘ DOANH NGHIỆP (ORACLE DATABASE 23ai)

- **Trường:** Đại học Ngoại ngữ – Tin học TP.HCM (HUFLIT) — Khoa Công nghệ Thông tin
- **Học phần:** Hệ quản trị Cơ sở dữ liệu (Oracle Database 23ai)
- **Giảng viên hướng dẫn:** ThS. Lê Thị Minh Nguyện
- **Nhóm thực hiện:** Nhóm 12 — Đề tài số 08 (Nhóm 3: PL/SQL, Functions, Exception Handling)
  - `24DH113268` — **Nguyễn Quốc Huy** (Nhóm trưởng)
  - `24DH113249` — **Phạm Thành Đức**
  - `24DH141906` — **Nguyễn Thế Vinh**

---

## 1. Cấu trúc thư mục dự án

- `docker-compose.yml`, `.env`: Cấu hình container `Oracle Database 23ai Free` (PDB `FREEPDB1`, port `1521`).
- `docker/init/01_auto_init.sh`: Tự động khởi tạo schema `EWALLET_APP` khi container chạy lần đầu.
- `sql/`: Trọn bộ 11 script SQL/PL-SQL dùng cho Docker / SQL\*Plus (có dấu `/` phân tách khối cho `sqlplus`).
- `sql_dbeaver/`: Bản đồng bộ 11 script tối ưu riêng cho **DBeaver (`Alt+X`)** (đã lược bỏ dòng `/` đơn lẻ của SQL\*Plus để chạy một lần 0 lỗi `ORA-00900`).
  - `00_docker_sys_setup.sql`: Tạo user `EWALLET_APP` (chạy bằng `SYS AS SYSDBA` trên `FREEPDB1`).
  - `01_drop_objects.sql`: Dọn dẹp schema sạch sẽ để chạy lại từ đầu.
  - `02_tables_constraints.sql`: 9 bảng chuẩn 3NF + PK/FK/UK/CHECK + View `VW_TONG_HOP_VI_NHAN_VIEN`.
  - `03_sequences_indexes.sql`: 4 Sequences + Composite Covering Indexes.
  - `04_seed_data.sql`: Dữ liệu mẫu doanh nghiệp + **15.000 giao dịch lịch sử** cân bằng sổ cái kép.
  - `05_pkg_ngoai_le_vi.sql`: Package `PKG_NGOAI_LE_VI` với 10 User-Defined Exceptions (`PRAGMA EXCEPTION_INIT -20001..-20010`) và `SP_GHI_NHAT_KY_LOI` (`PRAGMA AUTONOMOUS_TRANSACTION`).
  - `06_functions.sql`: 5 Functions (`FN_TINH_PHI_GIAO_DICH`, `FN_TONG_CHI_TRONG_NGAY`, `FN_KIEM_TRA_VI_HOAT_DONG` dùng Oracle 23ai `BOOLEAN`, `FN_KIEM_TRA_DU_SO_DU`, `FN_XEP_HANG_MUC_VI`).
  - `07_pkg_quan_ly_vi.sql`: Package `PKG_QUAN_LY_VI` (Nạp, Rút, Chuyển tiền chống Deadlock, Thanh toán DV, Hoàn tiền, Khoá/Mở ví, Đối soát bằng **Explicit Cursor**).
  - `08_triggers.sql`: 3 Triggers (bảo vệ số dư ví khoá, audit trạng thái ví, và **Compound Trigger** tránh lỗi *Mutating Table ORA-04091*).
  - `09_test_scenarios.sql`: 9 kịch bản kiểm thử Happy Path + Ngoại lệ biên + Hoàn tiền + Đối soát + Compound Trigger.
  - `10_optimization_plans.sql`: Phân tích Execution Plan (`EXPLAIN PLAN` + `DBMS_XPLAN.DISPLAY`) trước và sau tối ưu cho 2 truy vấn trọng tâm.
- `backend/`: REST API (Node.js + Express + `oracledb` Thin Mode) + Giao diện Web (`public/`).
- `report/`: Báo cáo Word hoàn chỉnh (`BaoCao_DoAn_Nhom12_DeTai08.docx`) cùng mã nguồn Python sinh sơ đồ và tạo tài liệu.

---

## 2. Hướng dẫn chạy trên Docker (Hỗ trợ cả container `oracle23ai` có sẵn)

1. Mở Docker Desktop:
   - Nếu bạn đã có sẵn container `oracle23ai` (như `container-registry.oracle.com/database/free:23.7.0.0` đang chạy cổng `1521`), chỉ cần bấm **Start** (hoặc `docker start oracle23ai`) và kiểm tra `.env` khớp mật khẩu `SYS` (`ORACLE_PWD`).
   - Nếu chưa có container nào, chạy tại thư mục gốc dự án:
     ```powershell
     docker compose up -d
     ```
2. Đợi container chuyển sang trạng thái `healthy`:
   ```powershell
   docker ps
   ```
3. Chạy tự động toàn bộ 11 script SQL + Kiểm thử + Execution Plan (`run_sql_docker.ps1` tự động nhận diện `oracle23ai` hoặc `oracle23ai_ewallet`):
   ```powershell
   .\scripts\run_sql_docker.ps1
   ```

---

## 3. Hướng dẫn kết nối và chạy trên DBeaver

### Bước 1: Tạo User (nếu chưa chạy qua Docker init)
- Tạo kết nối **Oracle** trong DBeaver:
  - Host: `localhost` | Port: `1521`
  - Database/Service Name: `FREEPDB1` (chọn **Service Name**, không chọn SID)
  - Username: `SYS` (Role: `SYSDBA`) | Password: `Oracle23ai`
- Mở file `sql/00_docker_sys_setup.sql` và nhấn **Execute SQL Script (`Alt+X`)**.

### Bước 2: Kết nối bằng tài khoản ứng dụng & chạy kịch bản
- Tạo kết nối mới trong DBeaver với:
  - Service Name: `FREEPDB1`
  - Username: `EWALLET_APP` | Password: `Ewallet2026`
- Mở và nhấn **`Alt+X` (Execute SQL Script)** các file trong thư mục **`sql_dbeaver/`** (đã tối ưu bỏ `/` để không gặp lỗi `ORA-00900` trên DBeaver) lần lượt theo đúng thứ tự:
  `01_drop_objects.sql` → `02_tables_constraints.sql` → `03_sequences_indexes.sql` → `04_seed_data.sql` → `05_pkg_ngoai_le_vi.sql` → `06_functions.sql` → `07_pkg_quan_ly_vi.sql` → `08_triggers.sql` → `09_test_scenarios.sql` → `10_optimization_plans.sql`.
- Lưu ý trong DBeaver: Để xem kết quả `DBMS_OUTPUT.PUT_LINE` khi chạy `09_test_scenarios.sql`, bật biểu tượng **Server Output** (`Ctrl+Shift+O`) trên thanh công cụ SQL Editor của DBeaver.

---

## 4. Hướng dẫn chạy Ứng dụng Web (API + Frontend)

```powershell
cd backend
npm install
npm start
```
Sau đó mở trình duyệt tại: `http://localhost:3000`
