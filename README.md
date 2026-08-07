# MSI Control (msictl) — Panduan Lengkap dari Awal

Tool CLI sederhana untuk mengatur setting laptop MSI (GF63 series) di Linux, tanpa perlu GUI. Panduan ini mencakup **semua langkah dari nol**: install driver kernel `msi-ec`, sampai pakai command `msictl`.

Ditulis & ditest di **Ubuntu 22.04 LTS**. Untuk distro lain, sesuaikan nama package manager-nya.

---

## 🗺️ Alur Besar

1. Install driver `msi-ec` (jembatan antara OS dan Embedded Controller laptop)
2. Verifikasi driver aktif
3. Install `msictl` (CLI wrapper biar gampang dipakai)
4. Mulai atur laptop dari terminal

---

## BAGIAN 1 — Install Driver `msi-ec`

### 1.1 Cek versi kernel

Driver ini butuh **minimal kernel 6.5.0**.

```bash
uname -r
```

Kalau versi kamu di bawah 6.5, upgrade dulu pakai HWE kernel (khusus Ubuntu 22.04 LTS):

```bash
sudo apt install --install-recommends linux-generic-hwe-22.04
sudo reboot
```

Setelah reboot, cek lagi dengan `uname -r` sampai versinya 6.5+.

### 1.2 Cek apakah laptop kamu didukung

Lihat daftar device yang sudah tested di halaman [msi-ec discussion #277](https://github.com/BeardOverflow/msi-ec/discussions/277). Kalau laptop kamu nggak ada di daftar, tetap bisa dicoba tapi kemungkinan ada fitur yang nggak berfungsi penuh.

### 1.3 Install dependency build

```bash
sudo apt update
sudo apt install build-essential linux-headers-generic dkms
```

### 1.4 Clone & install driver

```bash
git clone https://github.com/BeardOverflow/msi-ec
cd msi-ec
which dkms                 # pastikan dkms sudah terpasang
sudo make dkms-install
sudo reboot
```

### 1.5 Verifikasi driver aktif

Setelah reboot:

```bash
cat /sys/devices/platform/msi-ec/shift_mode
```

- Kalau muncul **"No such file or directory"** → driver belum aktif, cek ulang langkah 1.1–1.4.
- Kalau muncul value seperti `unspecified`, `comfort`, dll → **driver sudah jalan**, lanjut ke bagian berikutnya.

> Value `unspecified` itu normal kalau mode belum pernah di-set manual sejak boot — bukan error.

### 1.6 (Opsional) Aktifkan `ec_sys` untuk baca temperature & fan speed

```bash
sudo modprobe ec_sys write_support=1
lsmod | grep ec_sys
```

**Kalau muncul error `Operation not permitted`:** kemungkinan besar **Secure Boot** aktif di BIOS, yang memblokir module kernel unsigned. Solusinya:

1. Reboot, masuk BIOS/UEFI (biasanya tombol `Del` atau `F2` saat boot di MSI)
2. Masuk menu **Security → Secure Boot → Disabled**
3. Save & Exit, boot ke Ubuntu lagi
4. Ulangi command `modprobe` di atas

Biar auto-load setiap boot:

```bash
echo "ec_sys" | sudo tee -a /etc/modules
echo "options ec_sys write_support=1" | sudo tee /etc/modprobe.d/ec_sys.conf
```

---

## BAGIAN 2 — Install `msictl`

Setelah driver aktif, kamu punya dua pilihan: pakai command mentah `cat`/`echo` langsung ke sysfs, atau pakai `msictl` — script wrapper yang membungkus semua itu jadi command yang lebih gampang diingat.

### 2.1 Download file

Ambil file `msictl.sh` yang sudah disediakan (satu paket bareng README ini).

### 2.2 Pasang jadi command global

```bash
chmod +x msictl.sh
sudo cp msictl.sh /usr/local/bin/msictl
```

### 2.3 Tes

```bash
msictl status
```

Kalau muncul info shift mode, fan mode, temperature, dan battery threshold — instalasi berhasil dan kamu siap pakai.

---

## 📋 Persyaratan (Ringkasan)

- Driver **msi-ec** sudah terinstall dan aktif *(Bagian 1)*
- Script **msictl** sudah terpasang di `/usr/local/bin/` *(Bagian 2)*

---

## 🚀 Command Cheatsheet

| Command | Fungsi | Butuh sudo? |
|---|---|---|
| `msictl status` | Lihat semua status sekaligus | Tidak |
| `msictl modes` | Lihat daftar shift mode yang tersedia | Tidak |
| `msictl mode <value>` | Ganti shift mode | Ya |
| `msictl fanmodes` | Lihat daftar fan mode yang tersedia | Tidak |
| `msictl fanmode <value>` | Ganti fan mode | Ya |
| `msictl boost <on/off>` | Toggle cooler boost | Ya |
| `msictl battery <start> <end>` | Set batas charging baterai | Ya |
| `msictl kbd <0-3>` | Atur keyboard backlight | Ya |
| `msictl webcam <on/off>` | Toggle webcam | Ya |
| `msictl fnkey <left/right>` | Atur posisi tombol Fn | Ya |

Untuk command yang butuh sudo, jalankan seperti:
```bash
sudo msictl mode comfort
```

---

## 🎛️ Penjelasan Shift Mode (Performance Mode)

Shift mode mengatur seberapa "kencang" CPU & GPU boleh bekerja. Cek dulu mode apa saja yang tersedia di laptop kamu dengan `msictl modes`, karena tidak semua device support 4 mode ini.

| Mode | Penjelasan | Kapan dipakai |
|---|---|---|
| **eco** | Clock speed & voltage rendah untuk CPU/GPU. Mode hemat daya. | Kerja ringan (browsing, dokumen), mau baterai awet |
| **comfort** | Clock speed & voltage dinamis (menyesuaikan beban kerja). Mode seimbang. | Pemakaian sehari-hari, default recommended |
| **sport** | Clock speed & voltage penuh. Mode performa desktop standar. | Kerja berat (coding, compiling, multitasking) |
| **turbo** | Over-voltage & overclock CPU/GPU. Mode performa maksimal. | Gaming atau render berat — laptop lebih panas & fan lebih kencang |

Cara pakai:
```bash
msictl modes              # lihat mode yang tersedia di laptop kamu
sudo msictl mode comfort  # ganti ke mode comfort
msictl status             # cek mode aktif sekarang
```

**Catatan:** kalau `msictl status` menampilkan `unspecified`, itu artinya mode belum pernah di-set manual sejak boot — bukan error. Tinggal set salah satu mode di atas.

---

## 🌀 Penjelasan Fan Mode

Mengatur cara kerja fan/kipas laptop. Cek dulu pilihan yang tersedia dengan `msictl fanmodes`.

| Mode | Penjelasan |
|---|---|
| **auto** | Fan speed menyesuaikan otomatis berdasarkan suhu |
| **silent** | Fan dimatikan/diminimalkan — hening tapi suhu bisa naik |
| **basic** | Fan speed fixed 1-level untuk CPU/GPU (dalam persen) |
| **advanced** | Fan speed fixed 6-level untuk CPU/GPU (kontrol lebih detail) |

Cara pakai:
```bash
msictl fanmodes
sudo msictl fanmode auto
```

---

## 🔥 Cooler Boost

Fitur untuk memaksa fan berputar maksimal sesaat, biasanya dipakai saat suhu tinggi mendadak (misal sebelum sesi gaming/render berat).

```bash
sudo msictl boost on   # aktifkan cooler boost
sudo msictl boost off  # matikan
```

---

## 🔋 Battery Charge Limit

Membatasi kapan baterai mulai dan berhenti charging. Berguna untuk **memperpanjang umur baterai** kalau laptop sering dipakai colok charger terus-menerus.

```bash
sudo msictl battery <start> <end>
```

Contoh:
```bash
sudo msictl battery 0 80   # charging berhenti di 80% (rekomendasi untuk pemakaian harian)
sudo msictl battery 0 100  # charging sampai penuh (kalau butuh baterai maksimal, misal mau dibawa jalan jauh)
```

**Rekomendasi umum:** set ke `0 80` untuk pemakaian sehari-hari yang sering dicolok charger, biar baterai lebih awet dalam jangka panjang.

---

## ⌨️ Keyboard Backlight

```bash
sudo msictl kbd <0-3>
```

| Value | Arti |
|---|---|
| 0 | Off |
| 1 | On |
| 2 | Half (setengah kecerahan) |
| 3 | Full (kecerahan penuh) |

---

## 📷 Webcam

```bash
sudo msictl webcam on
sudo msictl webcam off
```

---

## ⌥ Posisi Tombol Fn/Windows

Menukar posisi fisik tombol Fn dan Windows di keyboard (kadang beda default antar region/model).

```bash
sudo msictl fnkey left    # Fn di kiri, Windows di kanan
sudo msictl fnkey right   # Fn di kanan, Windows di kiri
```

---

## 🩺 Troubleshooting

**Driver `msi-ec` tidak terbaca (`cat` menghasilkan "No such file or directory")**
Ulangi Bagian 1 dari langkah 1.1. Pastikan kernel sudah 6.5+ dan proses `dkms-install` selesai tanpa error, lalu **reboot**.

**`modprobe: ERROR: could not insert 'ec_sys': Operation not permitted`**
Ini karena Secure Boot aktif. Matikan Secure Boot di BIOS (lihat langkah 1.6), lalu ulangi.

**"msictl: command not found"**
Script belum ke-copy ke `/usr/local/bin/`, atau belum `chmod +x`. Ulangi Bagian 2.

**Command butuh sudo tapi lupa**
Tinggal ulangi dengan `sudo` di depan, contoh:
```bash
sudo msictl mode comfort
```

**Battery threshold nggak berubah**
Pastikan nama device baterainya kedetek benar. Cek manual dengan:
```bash
ls /sys/class/power_supply/
```
Kalau namanya bukan `BAT0`/`BAT1`, mungkin perlu edit script `msictl.sh` bagian deteksi baterai.

**Ingin pakai GUI (MControlCenter) daripada terminal**
Bisa, tapi di Ubuntu 22.04 biasanya perlu build manual dari source karena versi Qt6 di repo default terlalu lama (butuh Qt 6.4+, cmake 3.25+). Kalau butuh panduan build MControlCenter dari source, tanya terpisah — cukup panjang prosesnya dibanding pakai `msictl` langsung dari terminal.

---

## 📌 Quick Reference — Command Sering Dipakai

```bash
msictl status                # cek semua status
sudo msictl mode comfort     # mode harian
sudo msictl mode turbo       # mode gaming/render berat
sudo msictl battery 0 80     # limit baterai 80% (awetin baterai)
sudo msictl boost on         # paksa fan maksimal
```

---

## 📦 File yang Dibutuhkan

Paket lengkap untuk dikirim ke teman:
- `README.md` (panduan ini)
- `msictl.sh` (script CLI-nya)

Dua file ini sudah cukup — tidak perlu install GUI, tidak perlu clone `MControlCenter`, cukup driver `msi-ec` + `msictl`.
