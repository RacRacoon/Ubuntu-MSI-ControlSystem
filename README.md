# MSI Control (msictl) — Panduan Penggunaan

Tool CLI sederhana untuk mengatur setting laptop MSI (GF63) di Linux lewat driver `msi-ec`, tanpa perlu GUI.

---

## 📋 Persyaratan

- Driver **msi-ec** sudah terinstall dan aktif
- Cek dengan:
  ```bash
  cat /sys/devices/platform/msi-ec/shift_mode
  ```
  Kalau muncul value (bukan "No such file or directory"), driver sudah jalan.

---

## 🔧 Instalasi msictl

```bash
chmod +x msictl.sh
sudo cp msictl.sh /usr/local/bin/msictl
```

Setelah itu, command `msictl` bisa dipanggil dari mana saja di terminal.

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

**"msi-ec driver not found"**
Driver belum ke-load. Cek dengan:
```bash
lsmod | grep msi_ec
```
Kalau kosong, driver belum aktif — perlu reinstall/reload driver `msi-ec`.

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

---

## 📌 Quick Reference — Command Sering Dipakai

```bash
msictl status                # cek semua status
sudo msictl mode comfort     # mode harian
sudo msictl mode turbo       # mode gaming/render berat
sudo msictl battery 0 80     # limit baterai 80% (awetin baterai)
sudo msictl boost on         # paksa fan maksimal
```
