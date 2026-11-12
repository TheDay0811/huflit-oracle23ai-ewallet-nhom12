const state = {
  wallets: [],
  merchants: [],
  mode: 'transfer',
  lastRef: ''
};

const fmtVnd = (n) => Number(n || 0).toLocaleString('vi-VN') + ' đ';

function newRef(prefix = 'WEB') {
  return `${prefix}-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;
}

function showToast(msg, isOk = true) {
  const box = document.getElementById('toast-container');
  const el = document.createElement('div');
  el.className = `toast ${isOk ? 'ok' : 'err'}`;
  el.textContent = msg;
  box.appendChild(el);
  setTimeout(() => el.remove(), 4800);
}

async function api(url, options = {}) {
  const res = await fetch(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options
  });
  const data = await res.json();
  return { status: res.status, data };
}

// Navigation Tabs
document.querySelectorAll('.nav-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.nav-btn').forEach((b) => b.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach((p) => p.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
  });
});

// Transaction Mode Switch
document.querySelectorAll('.mode-btn').forEach((btn) => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.mode-btn').forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');
    state.mode = btn.dataset.mode;

    const grpSrc = document.getElementById('group-src');
    const grpDst = document.getElementById('group-dst');
    const grpMer = document.getElementById('group-merchant');

    grpSrc.classList.toggle('hidden', state.mode === 'deposit');
    grpDst.classList.toggle('hidden', state.mode !== 'transfer' && state.mode !== 'deposit');
    grpMer.classList.toggle('hidden', state.mode !== 'service');

    document.getElementById('tx-ref').value = newRef(state.mode.toUpperCase());
    updateFeePreview();
  });
});

async function checkHealth() {
  const pill = document.getElementById('db-status');
  try {
    const { data } = await api('/api/health');
    if (data.ok) {
      pill.className = 'db-pill ok';
      pill.textContent = `● Oracle 23ai (${data.database.PDB_NAME || 'FREEPDB1'})`;
    } else {
      pill.className = 'db-pill err';
      pill.textContent = '● Chưa kết nối Oracle 23ai';
    }
  } catch {
    pill.className = 'db-pill err';
    pill.textContent = '● API Offline';
  }
}

async function loadDashboard() {
  const { data } = await api('/api/dashboard');
  if (!data.ok) return;

  const w = data.walletStats;
  const t = data.txStats;
  const e = data.errStats;

  document.getElementById('stat-total-wallets').textContent = w.TONG_VI;
  document.getElementById('stat-wallet-sub').textContent = `${w.VI_HOAT_DONG} hoạt động · ${w.VI_BI_KHOA} bị khoá`;
  document.getElementById('stat-total-balance').textContent = fmtVnd(w.TONG_SO_DU_HE_THONG);
  document.getElementById('stat-total-tx').textContent = Number(t.TONG_GD).toLocaleString('vi-VN');
  document.getElementById('stat-tx-today').textContent = `Hôm nay: ${t.GD_HOM_NAY} GD (${fmtVnd(t.GIA_TRI_HOM_NAY)})`;
  document.getElementById('stat-total-err').textContent = e.TONG_LOI;

  const tbody = document.getElementById('tbl-recent-tx');
  tbody.innerHTML = data.recentTx
    .map((tx) => {
      const canRefund = tx.TRANG_THAI === 'THANH_CONG' && ['CHUYEN_NOI_BO', 'THANH_TOAN_DV'].includes(tx.MA_LOAI_GD);
      const pillCls = tx.TRANG_THAI === 'THANH_CONG' ? 'ok' : tx.TRANG_THAI === 'DA_HOAN_TIEN' ? 'warn' : 'lock';
      return `
        <tr>
          <td><strong>#${tx.MA_GD}</strong></td>
          <td><code>${tx.MA_THAM_CHIEU}</code></td>
          <td>${tx.MA_LOAI_GD}</td>
          <td>${tx.MA_VI_NGUON || 'EXTERNAL'} → ${tx.MA_VI_DICH || 'BANK'}</td>
          <td><strong>${fmtVnd(tx.SO_TIEN)}</strong></td>
          <td>${fmtVnd(tx.PHI_GD)}</td>
          <td><span class="pill ${pillCls}">${tx.TRANG_THAI}</span></td>
          <td>${tx.NGAY_TAO}</td>
          <td>
            ${canRefund ? `<button class="btn btn-sm btn-outline" onclick="refundTx(${tx.MA_GD})">Hoàn tiền</button>` : '—'}
          </td>
        </tr>
      `;
    })
    .join('');

  const errBody = document.getElementById('tbl-error-logs');
  errBody.innerHTML = data.recentErrs
    .map(
      (err) => `
      <tr>
        <td>#${err.MA_LOG}</td>
        <td><code>${err.MA_THAM_CHIEU || '—'}</code></td>
        <td><code>${err.TEN_MODULE}</code></td>
        <td><span class="pill lock">${err.MA_LOI_ORACLE}</span></td>
        <td><code>${err.MA_LOI_NGHIEP_VU}</code></td>
        <td>${err.THONG_DIEP_LOI}</td>
        <td>${err.THOI_GIAN_LOI}</td>
      </tr>
    `
    )
    .join('');
}

async function loadWalletsAndCatalog() {
  const [wRes, cRes] = await Promise.all([api('/api/wallets'), api('/api/catalog')]);
  if (wRes.data.ok) {
    state.wallets = wRes.data.wallets;
    renderWalletsTable();
    populateWalletSelects();
  }
  if (cRes.data.ok) {
    state.merchants = cRes.data.merchants;
    const sel = document.getElementById('tx-merchant');
    sel.innerHTML = state.merchants
      .map((m) => `<option value="${m.MA_DOI_TAC}">${m.TEN_DOI_TAC} (${m.LOAI_DICH_VU})</option>`)
      .join('');
  }
}

function renderWalletsTable() {
  const tbody = document.getElementById('tbl-wallets');
  tbody.innerHTML = state.wallets
    .map((w) => {
      const pillCls = w.TRANG_THAI === 'HOAT_DONG' ? 'ok' : 'lock';
      const nextStatus = w.TRANG_THAI === 'HOAT_DONG' ? 'TAM_KHOA' : 'HOAT_DONG';
      const toggleLabel = w.TRANG_THAI === 'HOAT_DONG' ? 'Khoá ví' : 'Mở khoá';
      const toggleBtnCls = w.TRANG_THAI === 'HOAT_DONG' ? 'btn-danger' : 'btn-success';

      return `
        <tr>
          <td><strong>${w.MA_VI}</strong><br/><small>${w.SO_TAI_KHOAN}</small></td>
          <td><strong>${w.HO_TEN}</strong><br/><small>${w.TEN_PB}</small></td>
          <td><span class="pill info">${w.LOAI_VI}</span></td>
          <td><strong>${fmtVnd(w.SO_DU_KHA_DUNG)}</strong></td>
          <td>${fmtVnd(w.DA_CHI_HOM_NAY)} / ${fmtVnd(w.HAN_MUC_NGAY)}</td>
          <td><span class="pill warn">${w.HANG_MUC}</span></td>
          <td><span class="pill ${pillCls}">${w.TRANG_THAI}</span></td>
          <td>
            <button class="btn btn-sm btn-outline" onclick="viewWalletDetail('${w.MA_VI}')">Sổ cái</button>
            ${
              w.TRANG_THAI !== 'DONG_VINH_VIEN'
                ? `<button class="btn btn-sm ${toggleBtnCls}" onclick="toggleWalletStatus('${w.MA_VI}','${nextStatus}')">${toggleLabel}</button>`
                : ''
            }
          </td>
        </tr>
      `;
    })
    .join('');
}

function populateWalletSelects() {
  const opts = state.wallets
    .map((w) => `<option value="${w.MA_VI}">${w.MA_VI} — ${w.HO_TEN} (${fmtVnd(w.SO_DU_KHA_DUNG)}) [${w.TRANG_THAI}]</option>`)
    .join('');
  const src = document.getElementById('tx-src');
  const dst = document.getElementById('tx-dst');
  const oldSrc = src.value;
  const oldDst = dst.value;
  src.innerHTML = opts;
  dst.innerHTML = opts;
  src.value = oldSrc || 'VI001';
  dst.value = oldDst || 'VI002';
}

window.viewWalletDetail = async (maVi) => {
  const { data } = await api(`/api/wallets/${maVi}/details`);
  if (!data.ok) return;
  document.getElementById('wallet-detail-box').classList.remove('hidden');
  document.getElementById('wallet-detail-title').textContent = `Chi tiết Sổ cái & Nhật ký trạng thái — Ví ${maVi}`;

  document.getElementById('tbl-wallet-ledger').innerHTML = data.ledger
    .map(
      (l) => `
      <tr>
        <td>#${l.MA_BUT_TOAN}</td>
        <td>#${l.MA_GD}</td>
        <td><span class="pill ${l.LOAI_BUT_TOAN === 'GHI_CO' ? 'ok' : 'lock'}">${l.LOAI_BUT_TOAN}</span></td>
        <td>${fmtVnd(l.SO_TIEN)}</td>
        <td>${fmtVnd(l.SO_DU_TRUOC)} → <strong>${fmtVnd(l.SO_DU_SAU)}</strong></td>
      </tr>
    `
    )
    .join('');

  document.getElementById('tbl-wallet-status-log').innerHTML =
    data.statusLog.length === 0
      ? '<tr><td colspan="4">Chưa có thay đổi trạng thái nào.</td></tr>'
      : data.statusLog
          .map(
            (s) => `
        <tr>
          <td>${s.TRANG_THAI_CU} → <strong>${s.TRANG_THAI_MOI}</strong></td>
          <td>${s.LY_DO}</td>
          <td>${s.NGUOI_THAY_DOI}</td>
          <td>${s.THOI_GIAN}</td>
        </tr>
      `
          )
          .join('');
};

document.getElementById('btn-close-detail').addEventListener('click', () => {
  document.getElementById('wallet-detail-box').classList.add('hidden');
});

window.toggleWalletStatus = async (maVi, trangThaiMoi) => {
  const lyDo =
    trangThaiMoi === 'TAM_KHOA'
      ? 'Tạm khoá ví từ giao diện quản trị để kiểm thử bảo mật'
      : 'Mở khoá lại ví sau khi xác minh';
  const { data } = await api(`/api/wallets/${maVi}/status`, {
    method: 'POST',
    body: JSON.stringify({ trangThaiMoi, lyDo, nguoiThucHien: 'WEB_ADMIN' })
  });
  showToast(data.thongBao, data.ok);
  await refreshAll();
};

window.refundTx = async (maGdGoc) => {
  const { data } = await api('/api/transactions/refund', {
    method: 'POST',
    body: JSON.stringify({
      maGdGoc,
      maThamChieu: newRef('RFN'),
      lyDo: `Hoàn tiền cho GD #${maGdGoc} từ Dashboard`
    })
  });
  showToast(data.thongBao, data.ok);
  await refreshAll();
};

async function updateFeePreview() {
  const map = { transfer: 'CHUYEN_NOI_BO', deposit: 'NAP_TIEN', withdraw: 'RUT_TIEN', service: 'THANH_TOAN_DV' };
  const amount = Number(document.getElementById('tx-amount').value || 0);
  if (amount <= 0) return;
  const { data } = await api(`/api/fee?loaiGd=${map[state.mode]}&soTien=${amount}`);
  if (data.ok) {
    document.getElementById('fee-preview').textContent = `Phí giao dịch (FN_TINH_PHI_GIAO_DICH): ${fmtVnd(data.fee)}`;
  }
}

document.getElementById('tx-amount').addEventListener('input', updateFeePreview);
document.getElementById('btn-gen-ref').addEventListener('click', () => {
  document.getElementById('tx-ref').value = newRef(state.mode.toUpperCase());
});
document.getElementById('btn-replay-last').addEventListener('click', () => {
  if (!state.lastRef) {
    showToast('Chưa có mã tham chiếu giao dịch trước đó!', false);
    return;
  }
  document.getElementById('tx-ref').value = state.lastRef;
  document.getElementById('tx-form').requestSubmit();
});

document.getElementById('tx-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const maThamChieu = document.getElementById('tx-ref').value.trim();
  const soTien = Number(document.getElementById('tx-amount').value);
  const noiDung = document.getElementById('tx-note').value.trim();
  const maViNguon = document.getElementById('tx-src').value;
  const maViDich = document.getElementById('tx-dst').value;
  const maDoiTac = document.getElementById('tx-merchant').value;

  state.lastRef = maThamChieu;

  let endpoint = '/api/transactions/transfer';
  let payload = { maViNguon, maViDich, soTien, maThamChieu, noiDung };

  if (state.mode === 'deposit') {
    endpoint = '/api/transactions/deposit';
    payload = { maVi: maViDich, soTien, maThamChieu, noiDung };
  } else if (state.mode === 'withdraw') {
    endpoint = '/api/transactions/withdraw';
    payload = { maVi: maViNguon, soTien, maThamChieu, noiDung };
  } else if (state.mode === 'service') {
    endpoint = '/api/transactions/pay-service';
    payload = { maViNguon, maDoiTac, soTien, maThamChieu, noiDung };
  }

  const { status, data } = await api(endpoint, { method: 'POST', body: JSON.stringify(payload) });
  document.getElementById('tx-result-box').textContent = JSON.stringify({ httpStatus: status, ...data }, null, 2);
  showToast(data.thongBao || 'Đã nhận phản hồi từ Oracle 23ai', data.ok);
  await refreshAll();
});

// Quick Exception Lab
document.querySelectorAll('.test-btn').forEach((btn) => {
  btn.addEventListener('click', async () => {
    const kind = btn.dataset.test;
    let res;
    if (kind === 'insufficient') {
      res = await api('/api/transactions/transfer', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI007', maViDich: 'VI002', soTien: 5000000, noiDung: 'Lab test -20001 Số dư không đủ' })
      });
    } else if (kind === 'locked') {
      res = await api('/api/transactions/transfer', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI006', maViDich: 'VI001', soTien: 100000, noiDung: 'Lab test -20003 Ví bị khoá' })
      });
    } else if (kind === 'duplicate') {
      res = await api('/api/test-concurrent-duplicate', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI001', maViDich: 'VI002', soTien: 50000 })
      });
    } else if (kind === 'limit') {
      res = await api('/api/transactions/transfer', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI005', maViDich: 'VI001', soTien: 25000000, noiDung: 'Lab test -20005 Vượt hạn mức ngày' })
      });
    } else if (kind === 'same') {
      res = await api('/api/transactions/transfer', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI001', maViDich: 'VI001', soTien: 100000, noiDung: 'Lab test -20007 Chuyển cùng ví' })
      });
    } else if (kind === 'notfound') {
      res = await api('/api/transactions/transfer', {
        method: 'POST',
        body: JSON.stringify({ maViNguon: 'VI_KHONG_TON_TAI', maViDich: 'VI001', soTien: 100000, noiDung: 'Lab test -20004 Ví không tồn tại' })
      });
    }

    document.getElementById('exception-test-output').textContent = JSON.stringify(res.data, null, 2);
    await refreshAll();
  });
});

// Explicit Cursor Reconciliation
document.getElementById('btn-run-reconcile').addEventListener('click', async () => {
  const { data } = await api('/api/reconcile', { method: 'POST' });
  document.getElementById('reconcile-output').textContent = JSON.stringify(data, null, 2);
  showToast(data.thongBao, data.ok);
});

async function refreshAll() {
  await Promise.all([checkHealth(), loadDashboard(), loadWalletsAndCatalog()]);
}

document.getElementById('btn-refresh').addEventListener('click', refreshAll);

// Init
document.getElementById('tx-ref').value = newRef('TRF');
refreshAll();
