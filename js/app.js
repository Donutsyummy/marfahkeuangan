const App = {
  user: null,
  data: {},
  chatChannel: null,
  onlineChannel: null,

  init() {
    this.checkSession();
    this.bindEvents();
  },

  async checkSession() {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) return;
    await this.loadUser(session.user.id);
    if (this.user) this.showApp();
  },

  async loadUser(authId) {
    const { data } = await supabaseClient.from('users').select('*').eq('auth_id', authId).single();
    if (data) {
      this.user = data;
      await this.updateLastSeen();
      this.subscribeRealtime();
    }
  },

  async updateLastSeen() {
    await supabaseClient.from('users').update({ last_seen: new Date().toISOString() }).eq('id', this.user.id);
  },

  subscribeRealtime() {
    this.chatChannel = supabaseClient.channel('chat_messages')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages' }, payload => {
        if (!this.data.chat) this.data.chat = [];
        this.data.chat.push(payload.new);
        const el = document.getElementById('pageChat');
        if (el?.classList.contains('active')) this.renderChat();
      })
      .subscribe();

    this.onlineChannel = supabaseClient.channel('online_users')
      .on('presence', { event: 'sync' }, () => {
        const el = document.getElementById('pageAnggota');
        if (el?.classList.contains('active')) this.renderAnggota();
      })
      .subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          await this.onlineChannel.track({ user_id: this.user.id, username: this.user.username });
        }
      });
  },

  updateThemeIcon(theme) {
    const btn = document.getElementById('themeToggle');
    if (btn) {
      btn.textContent = theme === 'dark' ? '☀️' : '🌑';
    }
  },

  async handleLogin() {
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value.trim();
    const errorEl = document.getElementById('loginError');

    if (!username || !password) {
      errorEl.textContent = 'Isi username dan password!';
      errorEl.style.display = 'block';
      return;
    }

    const email = username.includes('@') ? username : username + '@laporanmrfh.local';
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) {
      errorEl.textContent = 'Login gagal: ' + error.message;
      errorEl.style.display = 'block';
      return;
    }

    await this.loadUser(data.user.id);
    if (this.user) {
      errorEl.style.display = 'none';
      this.showApp();
    } else {
      errorEl.textContent = 'Akun tidak ditemukan di sistem.';
      errorEl.style.display = 'block';
      await supabaseClient.auth.signOut();
    }
  },

  handleLogout() {
    if (this.chatChannel) { supabaseClient.removeChannel(this.chatChannel); this.chatChannel = null; }
    if (this.onlineChannel) { supabaseClient.removeChannel(this.onlineChannel); this.onlineChannel = null; }
    supabaseClient.auth.signOut();
    this.user = null;
    this.data = {};
    document.getElementById('loginPage').style.display = 'flex';
    document.getElementById('appLayout').classList.remove('active');
    document.getElementById('username').value = '';
    document.getElementById('password').value = '';
  },

  showApp() {
    document.getElementById('loginPage').style.display = 'none';
    document.getElementById('appLayout').classList.add('active');
    document.getElementById('userName').textContent = this.user.name;
    document.getElementById('userAvatar').textContent = this.user.name.charAt(0).toUpperCase();
    document.getElementById('userRole').textContent = this.user.role;

    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    document.querySelectorAll('.data-form').forEach(f => {
      if (f.id === 'chatForm') return;
      f.style.display = canEdit ? 'block' : 'none';
    });
    document.querySelectorAll('.btn-export').forEach(b => b.style.display = 'inline-flex');
    const aktivitasNav = document.querySelector('.nav-item[data-page="aktivitas"]');
    if (aktivitasNav) aktivitasNav.style.display = canEdit ? 'flex' : 'none';

    this.updateBadges();
    this.navigate('dashboard');
  },

  async navigate(page) {
    document.querySelectorAll('.page-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

    const sectionId = 'page' + page.charAt(0).toUpperCase() + page.slice(1);
    const section = document.getElementById(sectionId);
    if (section) section.classList.add('active');

    const navItem = document.querySelector('.nav-item[data-page="' + page + '"]');
    if (navItem) navItem.classList.add('active');

    const titles = {
      dashboard:'Dashboard', penjualan:'Penjualan', kebutuhan:'Kebutuhan',
      kerjasama:'Kerjasama', bulanan:'Bulanan', tahunan:'Tahunan',
      aktivitas:'Aktivitas', kas:'Kas', anggota:'Anggota', chat:'Chat'
    };
    document.getElementById('pageTitle').innerHTML = 'Laporan <span>' + (titles[page] || page) + '</span>';

    if (page !== 'dashboard' && page !== 'aktivitas' && page !== 'anggota' && page !== 'chat') {
      await this.fetchData(page);
    }

    switch(page) {
      case 'dashboard': await this.renderDashboard(); break;
      case 'penjualan': this.renderPenjualan(); break;
      case 'kebutuhan': this.renderKebutuhan(); break;
      case 'kerjasama': this.renderKerjasama(); break;
      case 'bulanan': this.renderBulanan(); this.renderBulananSummary(); break;
      case 'tahunan': this.renderTahunan(); this.renderTahunanSummary(); break;
      case 'kas': this.renderKas(); break;
      case 'anggota': this.renderAnggota(); break;
      case 'chat': this.renderChat(); break;
      case 'aktivitas': await this.renderAktivitas(); break;
    }

    if (page !== 'dashboard' && page !== 'aktivitas' && page !== 'anggota') {
      this.logActivity('Melihat', titles[page] || page, 'Membuka halaman ' + (titles[page] || page));
    }
  },

  formatRupiah(amount) {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency', currency: 'IDR',
      minimumFractionDigits: 0, maximumFractionDigits: 0
    }).format(amount || 0);
  },

  getToday() { return new Date().toISOString().split('T')[0]; },

  logActivity(action, kategori, detail) {
    supabaseClient.from('aktivitas').insert({
      action, kategori, detail,
      nama: this.user?.name || 'Sistem',
      waktu: new Date().toISOString(),
      created_by: this.user?.id
    }).then(({ error }) => { if (error) console.error('Log activity error:', error); });
  },

  async updateBadges() {
    const tables = ['penjualan', 'kas', 'kebutuhan', 'kerjasama', 'bulanan', 'tahunan'];
    for (const table of tables) {
      const { count } = await supabaseClient.from(table).select('*', { count: 'exact', head: true });
      const badge = document.querySelector(`.nav-badge[data-page="${table}"]`);
      if (badge && count !== null) badge.textContent = count;
    }
  },

  async fetchData(type) {
    const { data, error } = await supabaseClient.from(type).select('*').order('id', { ascending: false });
    if (!error) this.data[type] = data || [];
  },

  async renderDashboard() {
    await Promise.all([
      this.fetchData('penjualan'),
      this.fetchData('kebutuhan'),
      this.fetchData('kerjasama'),
      this.fetchData('bulanan'),
      this.fetchData('tahunan'),
      this.fetchData('kas')
    ]);

    const pj = this.data.penjualan || [];
    const kb = this.data.kebutuhan || [];
    const ks = this.data.kerjasama || [];
    const bl = this.data.bulanan || [];
    const th = this.data.tahunan || [];
    const kss = this.data.kas || [];

    const totalPenjualan = pj.reduce((s, i) => s + (parseInt(i.untung_bersih) || 0), 0);
    const rugiPenjualan = pj.reduce((s, i) => s + (parseInt(i.rugi) || 0), 0);
    const totalKerjasama = ks.reduce((s, i) => s + (parseInt(i.untung_produk) || 0), 0);
    const rugiKerjasama = ks.reduce((s, i) => s + (parseInt(i.rugi) || 0), 0);
    const totalKebutuhan = kb.length;
    const totalEntries = pj.length + kb.length + ks.length + bl.length + th.length + kss.length;
    const kasMasuk = kss.filter(d => d.tipe === 'masuk').reduce((s, i) => s + (parseInt(i.jumlah) || 0), 0);
    const kasKeluar = kss.filter(d => d.tipe === 'keluar').reduce((s, i) => s + (parseInt(i.jumlah) || 0), 0);
    const kasSaldo = kasMasuk - kasKeluar;

    const totalUang = (totalPenjualan - rugiPenjualan) + (totalKerjasama - rugiKerjasama) + kasSaldo;

    const { data: setting } = await supabaseClient.from('settings').select('value').eq('key', 'total_uang_manual').single();
    const manualVal = setting?.value ? parseInt(setting.value) : null;
    const isManual = manualVal !== null;
    const finalTotal = isManual ? manualVal : totalUang;

    document.getElementById('statTotalUang').textContent = this.formatRupiah(finalTotal);
    document.getElementById('statKasSaldo').textContent = this.formatRupiah(kasSaldo);

    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const editBtn = document.getElementById('editTotalUangBtn');
    if (editBtn) editBtn.style.display = canEdit ? 'inline-flex' : 'none';

    const manualLabel = document.getElementById('totalUangLabel');
    if (manualLabel) manualLabel.textContent = isManual ? 'Total Uang Keseluruhan (manual)' : 'Total Uang Keseluruhan';

    document.getElementById('statPenjualan').textContent = this.formatRupiah(totalPenjualan);
    document.getElementById('statKerjasama').textContent = this.formatRupiah(totalKerjasama);
    document.getElementById('statKebutuhan').textContent = totalKebutuhan + ' kebutuhan';
    document.getElementById('statTotal').textContent = totalEntries + ' entri';

    document.querySelectorAll('.category-card').forEach(card => {
      card.onclick = () => this.navigate(card.dataset.page);
    });
  },

  async editTotalUang() {
    const { data: setting } = await supabaseClient.from('settings').select('value').eq('key', 'total_uang_manual').single();
    const current = setting?.value || '';
    const input = prompt('Masukkan Total Uang Keseluruhan (manual):\n(Kosongkan untuk kembali ke kalkulasi otomatis)', current);
    if (input === null) return;
    const trimmed = input.trim();
    if (trimmed === '') {
      await supabaseClient.from('settings').update({ value: null }).eq('key', 'total_uang_manual');
      this.logActivity('Mengedit', 'Total Uang', 'Mengembalikan total ke kalkulasi otomatis');
    } else {
      const val = parseInt(trimmed.replace(/[^0-9]/g, ''));
      if (isNaN(val) || val < 0) { alert('Masukkan angka yang valid!'); return; }
      await supabaseClient.from('settings').update({ value: String(val) }).eq('key', 'total_uang_manual');
      this.logActivity('Mengedit', 'Total Uang', 'Mengubah total ke Rp ' + Number(val).toLocaleString('id-ID'));
    }
    this.renderDashboard();
  },

  async savePenjualan() {
    const id = document.getElementById('pjId').value;
    const entry = {
      tanggal: document.getElementById('pjTanggal').value,
      modal: parseInt(document.getElementById('pjModal').value) || 0,
      produk: document.getElementById('pjProduk').value,
      untung_bersih: parseInt(document.getElementById('pjUntung').value) || 0,
      rugi: parseInt(document.getElementById('pjRugi').value) || 0,
      evaluasi: document.getElementById('pjEvaluasi').value,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('penjualan').update(entry).eq('id', id)
      : await supabaseClient.from('penjualan').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Penjualan', (id ? 'Mengedit' : 'Menambah') + ' data penjualan: ' + entry.produk);
    document.getElementById('formPenjualan').reset();
    document.getElementById('pjId').value = '';
    document.getElementById('pjSubmit').textContent = 'Simpan Penjualan';
    await this.fetchData('penjualan');
    this.renderPenjualan();
    this.renderDashboard();
  },

  renderPenjualan() {
    const tbody = document.getElementById('penjualanTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.penjualan || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="7">Belum ada data penjualan. Silakan tambah data baru.</td></tr>';
      return;
    }
    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.tanggal || '-') + '</td>' +
      '<td>' + this.formatRupiah(item.modal) + '</td>' +
      '<td>' + (item.produk || '-') + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_bersih) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi) + '</td>' +
      '<td>' + (item.evaluasi || '-') + '</td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editPenjualan(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deletePenjualan(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');
  },

  editPenjualan(id) {
    const item = (this.data.penjualan || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('pjId').value = id;
    document.getElementById('pjTanggal').value = item.tanggal;
    document.getElementById('pjModal').value = item.modal;
    document.getElementById('pjProduk').value = item.produk;
    document.getElementById('pjUntung').value = item.untung_bersih;
    document.getElementById('pjRugi').value = item.rugi;
    document.getElementById('pjEvaluasi').value = item.evaluasi;
    document.getElementById('pjSubmit').textContent = 'Update Penjualan';
    document.getElementById('pagePenjualan').scrollIntoView({ behavior: 'smooth' });
  },

  async deletePenjualan(id) {
    if (!confirm('Hapus data penjualan ini?')) return;
    const item = (this.data.penjualan || []).find(d => d.id === id);
    const { error } = await supabaseClient.from('penjualan').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Penjualan', 'Menghapus data penjualan: ' + (item?.produk || ''));
    await this.fetchData('penjualan');
    this.renderPenjualan();
    this.renderDashboard();
  },

  async saveKebutuhan() {
    const id = document.getElementById('kbId').value;
    const entry = {
      tanggal: document.getElementById('kbTanggal').value,
      bisnis_perlu: document.getElementById('kbBisnisPerlu').value,
      bisnis_untuk: document.getElementById('kbBisnisUntuk').value,
      kerjasama_perlu: document.getElementById('kbKerjasamaPerlu').value,
      kerjasama_untuk: document.getElementById('kbKerjasamaUntuk').value,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('kebutuhan').update(entry).eq('id', id)
      : await supabaseClient.from('kebutuhan').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Kebutuhan', (id ? 'Mengedit' : 'Menambah') + ' data kebutuhan');
    document.getElementById('formKebutuhan').reset();
    document.getElementById('kbId').value = '';
    document.getElementById('kbSubmit').textContent = 'Simpan Kebutuhan';
    await this.fetchData('kebutuhan');
    this.renderKebutuhan();
    this.renderDashboard();
  },

  renderKebutuhan() {
    const tbody = document.getElementById('kebutuhanTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.kebutuhan || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="6">Belum ada data kebutuhan.</td></tr>';
      return;
    }
    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.tanggal || '-') + '</td>' +
      '<td>' + (item.bisnis_perlu || '-') + '</td>' +
      '<td>' + (item.bisnis_untuk || '-') + '</td>' +
      '<td>' + (item.kerjasama_perlu || '-') + '</td>' +
      '<td>' + (item.kerjasama_untuk || '-') + '</td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editKebutuhan(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deleteKebutuhan(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');
  },

  editKebutuhan(id) {
    const item = (this.data.kebutuhan || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('kbId').value = id;
    document.getElementById('kbTanggal').value = item.tanggal;
    document.getElementById('kbBisnisPerlu').value = item.bisnis_perlu;
    document.getElementById('kbBisnisUntuk').value = item.bisnis_untuk;
    document.getElementById('kbKerjasamaPerlu').value = item.kerjasama_perlu;
    document.getElementById('kbKerjasamaUntuk').value = item.kerjasama_untuk;
    document.getElementById('kbSubmit').textContent = 'Update Kebutuhan';
    document.getElementById('pageKebutuhan').scrollIntoView({ behavior: 'smooth' });
  },

  async deleteKebutuhan(id) {
    if (!confirm('Hapus data kebutuhan ini?')) return;
    const { error } = await supabaseClient.from('kebutuhan').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Kebutuhan', 'Menghapus data kebutuhan');
    await this.fetchData('kebutuhan');
    this.renderKebutuhan();
    this.renderDashboard();
  },

  async saveKas() {
    const id = document.getElementById('kasId').value;
    const entry = {
      tanggal: document.getElementById('kasTanggal').value,
      keterangan: document.getElementById('kasKeterangan').value,
      jumlah: parseInt(document.getElementById('kasJumlah').value) || 0,
      tipe: document.getElementById('kasTipe').value,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('kas').update(entry).eq('id', id)
      : await supabaseClient.from('kas').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Kas', (id ? 'Mengedit' : 'Menambah') + ' kas: ' + entry.keterangan + ' (' + (entry.tipe === 'masuk' ? '+' : '-') + ' Rp ' + entry.jumlah.toLocaleString('id-ID') + ')');
    document.getElementById('formKas').reset();
    document.getElementById('kasId').value = '';
    document.getElementById('kasSubmit').textContent = 'Simpan Kas';
    await this.fetchData('kas');
    this.renderKas();
    this.renderDashboard();
  },

  renderKas() {
    const tbody = document.getElementById('kasTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.kas || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="5">Belum ada data kas.</td></tr>';
      return;
    }
    const totalMasuk = data.filter(d => d.tipe === 'masuk').reduce((s, i) => s + (parseInt(i.jumlah) || 0), 0);
    const totalKeluar = data.filter(d => d.tipe === 'keluar').reduce((s, i) => s + (parseInt(i.jumlah) || 0), 0);
    const saldo = totalMasuk - totalKeluar;

    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.tanggal || '-') + '</td>' +
      '<td>' + (item.keterangan || '-') + '</td>' +
      '<td>' + this.formatRupiah(item.jumlah) + '</td>' +
      '<td><span class="badge ' + (item.tipe === 'masuk' ? 'badge-profit' : 'badge-loss') + '">' + (item.tipe === 'masuk' ? 'Pemasukan' : 'Pengeluaran') + '</span></td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editKas(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deleteKas(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');

    const saldoEl = document.getElementById('kasSaldo');
    if (saldoEl) { saldoEl.textContent = this.formatRupiah(saldo); saldoEl.className = saldo >= 0 ? 'text-success' : 'text-danger'; }
    document.getElementById('kasTotalMasuk').textContent = this.formatRupiah(totalMasuk);
    document.getElementById('kasTotalKeluar').textContent = this.formatRupiah(totalKeluar);
  },

  editKas(id) {
    const item = (this.data.kas || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('kasId').value = id;
    document.getElementById('kasTanggal').value = item.tanggal;
    document.getElementById('kasKeterangan').value = item.keterangan;
    document.getElementById('kasJumlah').value = item.jumlah;
    document.getElementById('kasTipe').value = item.tipe;
    document.getElementById('kasSubmit').textContent = 'Update Kas';
    document.getElementById('pageKas').scrollIntoView({ behavior: 'smooth' });
  },

  async deleteKas(id) {
    if (!confirm('Hapus data kas ini?')) return;
    const item = (this.data.kas || []).find(d => d.id === id);
    const { error } = await supabaseClient.from('kas').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Kas', 'Menghapus kas: ' + (item?.keterangan || ''));
    await this.fetchData('kas');
    this.renderKas();
    this.renderDashboard();
  },

  async saveKerjasama() {
    const id = document.getElementById('ksId').value;
    const entry = {
      tanggal: document.getElementById('ksTanggal').value,
      untung_produk: parseInt(document.getElementById('ksUntung').value) || 0,
      bagi_hasil: parseInt(document.getElementById('ksBagiHasil').value) || 0,
      rugi: parseInt(document.getElementById('ksRugi').value) || 0,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('kerjasama').update(entry).eq('id', id)
      : await supabaseClient.from('kerjasama').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Kerjasama', (id ? 'Mengedit' : 'Menambah') + ' data kerjasama');
    document.getElementById('formKerjasama').reset();
    document.getElementById('ksId').value = '';
    document.getElementById('ksSubmit').textContent = 'Simpan Kerjasama';
    await this.fetchData('kerjasama');
    this.renderKerjasama();
    this.renderDashboard();
  },

  renderKerjasama() {
    const tbody = document.getElementById('kerjasamaTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.kerjasama || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="5">Belum ada data kerjasama.</td></tr>';
      return;
    }
    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.tanggal || '-') + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_produk) + '</td>' +
      '<td class="text-gold">' + this.formatRupiah(item.bagi_hasil) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi) + '</td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editKerjasama(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deleteKerjasama(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');
  },

  editKerjasama(id) {
    const item = (this.data.kerjasama || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('ksId').value = id;
    document.getElementById('ksTanggal').value = item.tanggal;
    document.getElementById('ksUntung').value = item.untung_produk;
    document.getElementById('ksBagiHasil').value = item.bagi_hasil;
    document.getElementById('ksRugi').value = item.rugi;
    document.getElementById('ksSubmit').textContent = 'Update Kerjasama';
    document.getElementById('pageKerjasama').scrollIntoView({ behavior: 'smooth' });
  },

  async deleteKerjasama(id) {
    if (!confirm('Hapus data kerjasama ini?')) return;
    const { error } = await supabaseClient.from('kerjasama').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Kerjasama', 'Menghapus data kerjasama');
    await this.fetchData('kerjasama');
    this.renderKerjasama();
    this.renderDashboard();
  },

  async saveBulanan() {
    const id = document.getElementById('blId').value;
    const entry = {
      periode: document.getElementById('blPeriode').value,
      untung_keseluruhan: parseInt(document.getElementById('blUntungKeseluruhan').value) || 0,
      rugi_keseluruhan: parseInt(document.getElementById('blRugiKeseluruhan').value) || 0,
      untung_bisnis: parseInt(document.getElementById('blUntungBisnis').value) || 0,
      rugi_bisnis: parseInt(document.getElementById('blRugiBisnis').value) || 0,
      untung_kerjasama: parseInt(document.getElementById('blUntungKerjasama').value) || 0,
      rugi_kerjasama: parseInt(document.getElementById('blRugiKerjasama').value) || 0,
      target: document.getElementById('blTarget').value,
      evaluasi: document.getElementById('blEvaluasi').value,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('bulanan').update(entry).eq('id', id)
      : await supabaseClient.from('bulanan').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Bulanan', (id ? 'Mengedit' : 'Menambah') + ' laporan bulanan ' + entry.periode);
    document.getElementById('formBulanan').reset();
    document.getElementById('blId').value = '';
    document.getElementById('blSubmit').textContent = 'Simpan Laporan Bulanan';
    await this.fetchData('bulanan');
    this.renderBulanan();
    this.renderDashboard();
  },

  renderBulanan() {
    const tbody = document.getElementById('bulananTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.bulanan || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="10">Belum ada laporan bulanan.</td></tr>';
      return;
    }
    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.periode || '-') + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_keseluruhan) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_keseluruhan) + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_bisnis) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_bisnis) + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_kerjasama) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_kerjasama) + '</td>' +
      '<td>' + (item.target || '-') + '</td>' +
      '<td>' + (item.evaluasi || '-') + '</td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editBulanan(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deleteBulanan(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');
  },

  editBulanan(id) {
    const item = (this.data.bulanan || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('blId').value = id;
    document.getElementById('blPeriode').value = item.periode;
    document.getElementById('blUntungKeseluruhan').value = item.untung_keseluruhan;
    document.getElementById('blRugiKeseluruhan').value = item.rugi_keseluruhan;
    document.getElementById('blUntungBisnis').value = item.untung_bisnis;
    document.getElementById('blRugiBisnis').value = item.rugi_bisnis;
    document.getElementById('blUntungKerjasama').value = item.untung_kerjasama;
    document.getElementById('blRugiKerjasama').value = item.rugi_kerjasama;
    document.getElementById('blTarget').value = item.target;
    document.getElementById('blEvaluasi').value = item.evaluasi;
    document.getElementById('blSubmit').textContent = 'Update Laporan Bulanan';
    document.getElementById('pageBulanan').scrollIntoView({ behavior: 'smooth' });
  },

  async deleteBulanan(id) {
    if (!confirm('Hapus laporan bulanan ini?')) return;
    const { error } = await supabaseClient.from('bulanan').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Bulanan', 'Menghapus laporan bulanan');
    await this.fetchData('bulanan');
    this.renderBulanan();
    this.renderDashboard();
  },

  async saveTahunan() {
    const id = document.getElementById('thId').value;
    const entry = {
      tahun: document.getElementById('thTahun').value,
      untung_keseluruhan: parseInt(document.getElementById('thUntungKeseluruhan').value) || 0,
      rugi_keseluruhan: parseInt(document.getElementById('thRugiKeseluruhan').value) || 0,
      untung_bisnis: parseInt(document.getElementById('thUntungBisnis').value) || 0,
      rugi_bisnis: parseInt(document.getElementById('thRugiBisnis').value) || 0,
      untung_kerjasama: parseInt(document.getElementById('thUntungKerjasama').value) || 0,
      rugi_kerjasama: parseInt(document.getElementById('thRugiKerjasama').value) || 0,
      target: document.getElementById('thTarget').value,
      evaluasi: document.getElementById('thEvaluasi').value,
      created_by: this.user?.id
    };
    const { error } = id
      ? await supabaseClient.from('tahunan').update(entry).eq('id', id)
      : await supabaseClient.from('tahunan').insert(entry);
    if (error) { alert('Gagal menyimpan!'); return; }
    this.logActivity(id ? 'Mengedit' : 'Menambah', 'Tahunan', (id ? 'Mengedit' : 'Menambah') + ' laporan tahunan ' + entry.tahun);
    document.getElementById('formTahunan').reset();
    document.getElementById('thId').value = '';
    document.getElementById('thSubmit').textContent = 'Simpan Laporan Tahunan';
    await this.fetchData('tahunan');
    this.renderTahunan();
    this.renderDashboard();
  },

  renderTahunan() {
    const tbody = document.getElementById('tahunanTable');
    const canEdit = this.user.role === 'admin' || this.user.role === 'editor';
    const data = this.data.tahunan || [];
    if (data.length === 0) {
      tbody.innerHTML = '<tr class="empty-row"><td colspan="10">Belum ada laporan tahunan.</td></tr>';
      return;
    }
    tbody.innerHTML = data.map(item => '<tr>' +
      '<td>' + (item.tahun || '-') + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_keseluruhan) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_keseluruhan) + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_bisnis) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_bisnis) + '</td>' +
      '<td class="text-success">' + this.formatRupiah(item.untung_kerjasama) + '</td>' +
      '<td class="text-danger">' + this.formatRupiah(item.rugi_kerjasama) + '</td>' +
      '<td>' + (item.target || '-') + '</td>' +
      '<td>' + (item.evaluasi || '-') + '</td>' +
      '<td class="actions-cell">' + (canEdit ?
        '<button class="btn-icon" onclick="App.editTahunan(' + item.id + ')" title="Edit">âœï¸</button>' +
        '<button class="btn-icon" onclick="App.deleteTahunan(' + item.id + ')" title="Hapus">ðŸ—‘ï¸</button>' : '') +
      '</td></tr>').join('');
  },

  editTahunan(id) {
    const item = (this.data.tahunan || []).find(d => d.id === id);
    if (!item) return;
    document.getElementById('thId').value = id;
    document.getElementById('thTahun').value = item.tahun;
    document.getElementById('thUntungKeseluruhan').value = item.untung_keseluruhan;
    document.getElementById('thRugiKeseluruhan').value = item.rugi_keseluruhan;
    document.getElementById('thUntungBisnis').value = item.untung_bisnis;
    document.getElementById('thRugiBisnis').value = item.rugi_bisnis;
    document.getElementById('thUntungKerjasama').value = item.untung_kerjasama;
    document.getElementById('thRugiKerjasama').value = item.rugi_kerjasama;
    document.getElementById('thTarget').value = item.target;
    document.getElementById('thEvaluasi').value = item.evaluasi;
    document.getElementById('thSubmit').textContent = 'Update Laporan Tahunan';
    document.getElementById('pageTahunan').scrollIntoView({ behavior: 'smooth' });
  },

  async deleteTahunan(id) {
    if (!confirm('Hapus laporan tahunan ini?')) return;
    const { error } = await supabaseClient.from('tahunan').delete().eq('id', id);
    if (error) { alert('Gagal menghapus!'); return; }
    this.logActivity('Menghapus', 'Tahunan', 'Menghapus laporan tahunan');
    await this.fetchData('tahunan');
    this.renderTahunan();
    this.renderDashboard();
  },

  renderBulananSummary() {
    const data = this.data.bulanan || [];
    if (data.length === 0) {
      ['blSummaryUntung', 'blSummaryRugi', 'blSummaryNetto'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = 'Rp 0';
      });
      return;
    }
    const untung = data.reduce((s, d) => s + (parseInt(d.untung_keseluruhan) || 0), 0);
    const rugi = data.reduce((s, d) => s + (parseInt(d.rugi_keseluruhan) || 0), 0);
    const netto = untung - rugi;

    const elUntung = document.getElementById('blSummaryUntung');
    const elRugi = document.getElementById('blSummaryRugi');
    const elNetto = document.getElementById('blSummaryNetto');

    if (elUntung) elUntung.textContent = this.formatRupiah(untung);
    if (elRugi) elRugi.textContent = this.formatRupiah(rugi);
    if (elNetto) {
      elNetto.textContent = this.formatRupiah(netto);
      elNetto.className = 'recap-value ' + (netto >= 0 ? 'neutral' : 'negative');
    }
  },

  renderTahunanSummary() {
    const data = this.data.tahunan || [];
    if (data.length === 0) {
      ['thSummaryUntung', 'thSummaryRugi', 'thSummaryNetto'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = 'Rp 0';
      });
      return;
    }
    const untung = data.reduce((s, d) => s + (parseInt(d.untung_keseluruhan) || 0), 0);
    const rugi = data.reduce((s, d) => s + (parseInt(d.rugi_keseluruhan) || 0), 0);
    const netto = untung - rugi;

    const elUntung = document.getElementById('thSummaryUntung');
    const elRugi = document.getElementById('thSummaryRugi');
    const elNetto = document.getElementById('thSummaryNetto');

    if (elUntung) elUntung.textContent = this.formatRupiah(untung);
    if (elRugi) elRugi.textContent = this.formatRupiah(rugi);
    if (elNetto) {
      elNetto.textContent = this.formatRupiah(netto);
      elNetto.className = 'recap-value ' + (netto >= 0 ? 'neutral' : 'negative');
    }
  },

  openModal(type, data) {
    this.modalType = type;
    this.modalData = data;
    const titleEl = document.getElementById('modalTitle');
    const bodyEl = document.getElementById('modalBody');
    if (type === 'view') {
      titleEl.textContent = 'Detail ' + data.judul;
      bodyEl.innerHTML = '<div class="data-form" style="border-color: var(--gold);">' +
        Object.entries(data).map(([key, val]) =>
          '<div style="margin-bottom: 8px;"><strong style="color: var(--text-muted); text-transform: capitalize;">' +
          key.replace(/([A-Z])/g, ' $1') + ':</strong>' +
          '<span style="color: var(--text); float: right;">' + (val || '-') + '</span></div>'
        ).join('') + '</div>';
      document.querySelector('#modalForm .btn-gold').style.display = 'none';
    }
    document.getElementById('modalOverlay').classList.add('active');
  },

  closeModal() { document.getElementById('modalOverlay').classList.remove('active'); },
  handleModalSave() {},

  exportData(type) {
    const data = this.data[type];
    if (!data || data.length === 0) { alert('Tidak ada data untuk diexport.'); return; }
    const titles = { penjualan:'Penjualan', kebutuhan:'Kebutuhan', kerjasama:'Kerjasama', bulanan:'Bulanan', tahunan:'Tahunan', kas:'Kas', chat:'Chat' };
    let csv = 'Laporan ' + (titles[type] || type) + '\n\n';
    switch(type) {
      case 'penjualan':
        csv += 'Tanggal,Modal,Produk,Untung Bersih,Rugi,Evaluasi\n';
        data.forEach(d => { csv += '"' + d.tanggal + '","' + d.modal + '","' + d.produk + '","' + d.untung_bersih + '","' + d.rugi + '","' + d.evaluasi + '"\n'; });
        break;
      case 'kas':
        csv += 'Tanggal,Keterangan,Jumlah,Tipe\n';
        data.forEach(d => { csv += '"' + d.tanggal + '","' + d.keterangan + '","' + d.jumlah + '","' + d.tipe + '"\n'; });
        break;
      case 'kebutuhan':
        csv += 'Tanggal,Bisnis Perlu,Bisnis Untuk,Kerjasama Perlu,Kerjasama Untuk\n';
        data.forEach(d => { csv += '"' + d.tanggal + '","' + d.bisnis_perlu + '","' + d.bisnis_untuk + '","' + d.kerjasama_perlu + '","' + d.kerjasama_untuk + '"\n'; });
        break;
      case 'kerjasama':
        csv += 'Tanggal,Untung Produk,Bagi Hasil,Rugi\n';
        data.forEach(d => { csv += '"' + d.tanggal + '","' + d.untung_produk + '","' + d.bagi_hasil + '","' + d.rugi + '"\n'; });
        break;
      case 'bulanan':
      case 'tahunan':
        const periodLabel = type === 'bulanan' ? 'Periode' : 'Tahun';
        csv += periodLabel + ',Untung Keseluruhan,Rugi Keseluruhan,Untung Bisnis,Rugi Bisnis,Untung Kerjasama,Rugi Kerjasama,Target,Evaluasi\n';
        data.forEach(d => { csv += '"' + (d.periode || d.tahun) + '","' + d.untung_keseluruhan + '","' + d.rugi_keseluruhan + '","' + d.untung_bisnis + '","' + d.rugi_bisnis + '","' + d.untung_kerjasama + '","' + d.rugi_kerjasama + '","' + d.target + '","' + d.evaluasi + '"\n'; });
        break;
    }
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'Laporan_' + (titles[type] || type) + '_' + new Date().toISOString().split('T')[0] + '.csv';
    link.click();
    URL.revokeObjectURL(link.href);
  },

  async renderAktivitas() {
    const container = document.getElementById('aktivitasContainer');
    const { data: logs, error } = await supabaseClient.from('aktivitas').select('*').order('id', { ascending: false }).limit(100);
    if (error || !logs || logs.length === 0) {
      container.innerHTML = '<div style="text-align: center; padding: 40px; color: var(--text-muted);">' + (!logs ? 'Belum ada aktivitas tercatat.' : 'Gagal memuat aktivitas.') + '</div>';
      return;
    }
    const actionColors = { 'Melihat':'badge-neutral', 'Menambah':'badge-profit', 'Mengedit':'badge-neutral', 'Menghapus':'badge-loss' };
    container.innerHTML = logs.map(log => '' +
      '<div style="display: flex; align-items: flex-start; gap: 12px; padding: 12px 16px; border-bottom: 1px solid var(--border);">' +
      '<div style="width: 32px; height: 32px; border-radius: 50%; background: var(--gold); color: var(--black); display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px; flex-shrink: 0;">' +
      ((log.nama || '?').charAt(0).toUpperCase()) + '</div>' +
      '<div style="flex: 1; min-width: 0;">' +
      '<div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">' +
      '<strong style="font-size: 13px;">' + this.escapeHtml(log.nama) + '</strong>' +
      '<span class="badge ' + (actionColors[log.action] || 'badge-neutral') + '">' + this.escapeHtml(log.action) + '</span>' +
      '<span style="font-size: 11px; color: var(--gold); padding: 2px 8px; background: rgba(212,175,55,0.1); border-radius: 4px;">' + this.escapeHtml(log.kategori) + '</span></div>' +
      '<div style="font-size: 12px; color: var(--text-muted); margin-top: 2px;">' + this.escapeHtml(log.detail || '') + '</div>' +
      '<div style="font-size: 11px; color: #555; margin-top: 2px;">' + this.escapeHtml(new Date(log.waktu).toLocaleString('id-ID')) + '</div></div></div>'
    ).join('');
  },

  renderAnggota() {
    const container = document.getElementById('anggotaContainer');
    const roleLabels = { admin:'Admin', editor:'Editor', viewer:'Pengamat' };
    const roleColors = { admin:'#D4AF37', editor:'#2ecc71', viewer:'#3498db' };

    supabaseClient.from('users').select('*').order('role').then(({ data: users, error }) => {
      if (error || !users) return;
      const presence = this.onlineChannel?.presence?.state() || {};
      const onlineUsernames = new Set();
      Object.values(presence).forEach(ps => { ps.forEach(p => { if (p.username) onlineUsernames.add(p.username); }); });

      const sorted = users.sort((a, b) => {
        const order = { admin:0, editor:1, viewer:2 };
        return (order[a.role] || 3) - (order[b.role] || 3);
      });
      container.innerHTML = sorted.map(user => {
        const isOnline = onlineUsernames.has(user.username);
        return '<div style="display: flex; align-items: center; gap: 14px; padding: 14px 20px; border-bottom: 1px solid var(--border); transition: var(--transition);">' +
          '<div style="position: relative; flex-shrink: 0;">' +
          '<div style="width: 40px; height: 40px; border-radius: 50%; background: ' + (roleColors[user.role] || '#555') + '; color: var(--black); display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 16px;">' +
          (user.name || '?').charAt(0).toUpperCase() + '</div>' +
          '<div style="position: absolute; bottom: 0; right: 0; width: 14px; height: 14px; border-radius: 50%; background: ' + (isOnline ? '#2ecc71' : '#555') + '; border: 2px solid var(--black-2); transition: background 0.3s;"></div></div>' +
          '<div style="flex: 1; min-width: 0;">' +
          '<div style="font-weight: 600; font-size: 14px; color: var(--text);">' + this.escapeHtml(user.name) + '</div>' +
          '<div style="font-size: 12px; color: ' + (roleColors[user.role] || '#999') + ';">' +
          (roleLabels[user.role] || user.role) + (user.username === this.user?.username ? ' <span style="color: var(--text-muted);">(Anda)</span>' : '') + '</div></div>' +
          '<div style="font-size: 12px; color: ' + (isOnline ? '#2ecc71' : '#555') + '; font-weight: 500; flex-shrink: 0;">' +
          (isOnline ? 'â— Online' : 'â—‹ Offline') + '</div></div>';
      }).join('');
    }).catch(() => {
      container.innerHTML = '<div style="text-align: center; padding: 40px; color: var(--text-muted);">Gagal memuat data anggota.</div>';
    });
  },

  sendChat() {
    if (!this.user) return alert('Login dulu!');
    const input = document.getElementById('chatInput');
    if (!input) return;
    const text = input.value.trim();
    if (!text) return;
    supabaseClient.from('chat_messages').insert({
      text,
      username: this.user.username,
      nama: this.user.name,
      waktu: new Date().toISOString()
    }).then(({ error }) => {
      if (error) alert('Gagal mengirim pesan: ' + error.message);
    });
    input.value = '';
  },

  renderChat() {
    const container = document.getElementById('chatContainer');
    const messages = this.data.chat || [];
    if (messages.length === 0) {
      container.innerHTML = '<div style="text-align: center; padding: 40px; color: var(--text-muted);">Belum ada pesan. Mulai percakapan!</div>';
      return;
    }
    const last = messages.slice(-50);
    container.innerHTML = last.map(m => {
      const isMe = m.username === this.user?.username;
      const time = new Date(m.waktu).toLocaleTimeString('id-ID', { hour:'2-digit', minute:'2-digit' });
      return '<div style="display: flex; align-items: flex-start; gap: 10px; padding: 10px 16px; border-bottom: 1px solid var(--border); ' + (isMe ? 'background: rgba(212,175,55,0.03);' : '') + '">' +
        '<div style="width: 30px; height: 30px; border-radius: 50%; background: ' + (isMe ? 'var(--gold)' : 'var(--black-4)') + '; color: ' + (isMe ? 'var(--black)' : 'var(--text)') + '; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 12px; flex-shrink: 0;">' +
        (m.nama || '?').charAt(0).toUpperCase() + '</div>' +
        '<div style="flex: 1; min-width: 0;">' +
        '<div style="display: flex; align-items: center; gap: 8px;">' +
        '<strong style="font-size: 12px; color: ' + (isMe ? 'var(--gold)' : 'var(--text)') + ';">' + this.escapeHtml(m.nama) + '</strong>' +
        '<span style="font-size: 10px; color: var(--text-muted);">' + time + '</span></div>' +
        '<div style="font-size: 13px; color: var(--text); margin-top: 2px; word-wrap: break-word;">' + this.escapeHtml(m.text) + '</div></div></div>';
    }).join('');
    container.scrollTop = container.scrollHeight;
  },

  escapeHtml(text) {
    const d = document.createElement('div');
    d.textContent = text;
    return d.innerHTML;
  },

  bindEvents() {
    document.getElementById('loginForm').addEventListener('submit', (e) => {
      e.preventDefault();
      this.handleLogin();
    });
    document.getElementById('logoutBtn').addEventListener('click', () => { this.handleLogout(); });
    
    // Theme toggle dark mode
    document.getElementById('themeToggle').addEventListener('click', () => {
      const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
      const newTheme = currentTheme === 'light' ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', newTheme);
      localStorage.setItem('marfah-theme', newTheme);
    });
    
    // Load saved theme
    const savedTheme = localStorage.getItem('marfah-theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    this.updateThemeIcon(savedTheme);
    
    document.getElementById('mobileMenuBtn').addEventListener('click', () => {
      document.getElementById('sidebar').classList.toggle('mobile-open');
      document.getElementById('sidebarOverlay').classList.toggle('active');
    });
    document.getElementById('sidebarOverlay').addEventListener('click', () => {
      document.getElementById('sidebar').classList.remove('mobile-open');
      document.getElementById('sidebarOverlay').classList.remove('active');
    });
    document.querySelectorAll('.nav-item').forEach(item => {
      item.addEventListener('click', () => {
        this.navigate(item.dataset.page);
        document.getElementById('sidebar').classList.remove('mobile-open');
        document.getElementById('sidebarOverlay').classList.remove('active');
      });
    });
    document.getElementById('formPenjualan').addEventListener('submit', (e) => { e.preventDefault(); this.savePenjualan(); });
    document.getElementById('formKas').addEventListener('submit', (e) => { e.preventDefault(); this.saveKas(); });
    document.getElementById('formKebutuhan').addEventListener('submit', (e) => { e.preventDefault(); this.saveKebutuhan(); });
    document.getElementById('formKerjasama').addEventListener('submit', (e) => { e.preventDefault(); this.saveKerjasama(); });
    document.getElementById('formBulanan').addEventListener('submit', (e) => { e.preventDefault(); this.saveBulanan(); });
    document.getElementById('formTahunan').addEventListener('submit', (e) => { e.preventDefault(); this.saveTahunan(); });
    document.getElementById('modalClose').addEventListener('click', () => this.closeModal());
    document.getElementById('modalOverlay').addEventListener('click', (e) => { if (e.target === e.currentTarget) this.closeModal(); });
    document.getElementById('modalForm').addEventListener('submit', (e) => { e.preventDefault(); this.handleModalSave(); });
    document.querySelectorAll('.btn-export').forEach(btn => {
      btn.addEventListener('click', () => { this.exportData(btn.dataset.export); });
    });
    document.getElementById('editTotalUangBtn').addEventListener('click', () => { this.editTotalUang(); });
    document.getElementById('chatSendBtn').addEventListener('click', () => { this.sendChat(); });
    document.getElementById('chatInput').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') { e.preventDefault(); this.sendChat(); }
    });
  }
};

document.addEventListener('DOMContentLoaded', () => App.init());

