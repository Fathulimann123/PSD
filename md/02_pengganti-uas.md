# Klasifikasi Spasial Tutupan Lahan (LULC) Jawa Timur (Random Forest & Sentinel-2)

| Keterangan      | Informasi                                                  |
| --------------- | ---------------------------------------------------------- |
| **Nama**        | Muhammad Fathul Iman Wahid                                 |
| **NIM**         | 240411100180                                               |
| **Mata Kuliah** | Proyek Sains Data                                          |
| **Topik**       | Klasifikasi Tutupan Lahan (LULC) Jawa Timur berbasis Spasial |

Dokumentasi ini menyajikan alur lengkap (*end-to-end pipeline*) klasifikasi tutupan lahan (*Land Use / Land Cover* - LULC) di **Provinsi Jawa Timur** berbasis citra satelit multispektral **Sentinel-2 Level-2A** dan algoritma **Random Forest**. Model mengklasifikasikan lahan ke dalam **5 kelas** (Bangunan, Pertanian, Air, Hutan, dan Mangrove) dan dievaluasi dengan **validasi antar-wilayah**, sehingga hasilnya menggambarkan kemampuan model pada lokasi yang belum pernah dilihat.

> 🌐 **Aplikasi Web Interaktif (Streamlit):** <https://dashboard-lulc-jatim.streamlit.app/>
> Peta klasifikasi, filter kelas lahan, *Confusion Matrix*, dan grafik kinerja model dapat diakses langsung secara publik.

Siklus proyek disusun mengikuti metodologi **CRISP-DM**:

1. **Business Understanding**: latar belakang, tujuan, dan ruang lingkup pemetaan.
2. **Data Understanding**: definisi kelas, karakteristik citra Sentinel-2, indeks spektral, dan sampel *ground truth*.
3. **Data Preprocessing**: ekstraksi piksel, kompresi spasial menjadi poligon, fitur tekstur spasial, dan pengelompokan wilayah.
4. **Modeling**: pelatihan model Random Forest dan ekspor model.
5. **Evaluation**: validasi antar-wilayah, metrik per kelas, dan analisis kesalahan.
6. **Deployment**: dashboard interaktif berbasis Streamlit.
7. **Kesimpulan**: ringkasan hasil, keterbatasan, dan saran pengembangan.

---

## Instalasi Library & Kebutuhan Lingkungan

```
pip install openeo geopandas rasterio scikit-learn pandas numpy folium plotly streamlit joblib
```

---

## 1. Business Understanding (Pemahaman Bisnis)

### 1.1. Latar Belakang

Pemetaan tutupan lahan sangat penting untuk pemantauan lahan pertanian, perencanaan tata ruang, ketahanan pangan, dan konservasi lingkungan. Jawa Timur memiliki bentang alam yang beragam: lahan pertanian yang luas, kawasan terbangun perkotaan, hutan pegunungan, perairan darat dan laut, serta ekosistem **mangrove** di sepanjang pesisir.

Interpretasi citra satelit secara manual memerlukan waktu dan tenaga yang besar serta rentan terhadap subjektivitas penafsir. Selain itu, wilayah yang luas membuat survei lapangan sulit dilakukan secara berkala. Pendekatan *machine learning* berbasis citra satelit multispektral dapat mengotomatiskan proses ini dan direplikasi setiap kali citra terbaru tersedia.

### 1.2. Tujuan Proyek

1. Membangun model klasifikasi tutupan lahan Jawa Timur ke dalam **5 kelas**: Bangunan, Pertanian, Air, Hutan, dan Mangrove.
2. Menerapkan algoritma **Random Forest** pada fitur tekstur spasial yang diturunkan dari citra Sentinel-2.
3. Mengevaluasi model dengan **validasi antar-wilayah** agar hasilnya tidak terlalu optimistis akibat kebocoran data spasial.
4. Menyajikan hasil klasifikasi dalam **dashboard interaktif** (peta satelit dengan filter kelas lahan dan grafik kinerja model) yang dapat diakses publik.

### 1.3. Ruang Lingkup dan Batasan

| Aspek               | Keterangan                                                            |
| ------------------- | --------------------------------------------------------------------- |
| **Wilayah**         | Lokasi sampel tersebar di berbagai wilayah Provinsi Jawa Timur        |
| **Sumber citra**    | Sentinel-2 Level-2A (*Bottom-of-Atmosphere Reflectance*)              |
| **Jumlah kelas**    | 5 kelas tutupan lahan                                                 |
| **Unit analisis**   | Poligon sampel (hasil agregasi dari piksel di dalamnya)               |
| **Algoritma**       | Random Forest                                                         |
| **Output**          | Model `.joblib` dan dashboard Streamlit                               |

---

## 2. Data Understanding (Pengumpulan & Pemahaman Data)

### 2.1. Definisi 5 Kelas Tutupan Lahan

| No | Kelas         | Label | Definisi Objek                                                           | Karakteristik Spektral Utama                                                      |
| -- | ------------- | ----- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| 1  | **Bangunan**  | `0`   | Permukiman, gedung, jalan aspal/beton, dan fasilitas industri            | Pantulan tinggi pada SWIR (B11) dan Red (B04); NDBI tinggi; NDVI rendah            |
| 2  | **Pertanian** | `1`   | Sawah dan lahan budidaya (termasuk fase genangan, tanam, dan bera)       | Berubah mengikuti fase tanam; NDVI sedang hingga tinggi saat fase hijau            |
| 3  | **Air**       | `2`   | Laut, danau, waduk, dan badan air lainnya                                | Penyerapan kuat pada NIR dan SWIR; NDWI dan MNDWI positif; NDVI negatif            |
| 4  | **Hutan**     | `3`   | Vegetasi berkanopi rapat di daratan, termasuk hutan pegunungan           | Pantulan NIR tinggi dan serapan Red kuat; NDVI tinggi                              |
| 5  | **Mangrove**  | `4`   | Hutan bakau di muara dan pantai berlumpur pasang surut                   | Sinyal vegetasi hijau dengan pengaruh substrat basah (SWIR relatif lebih rendah)   |

### 2.2. Citra Sentinel-2 Level-2A

Citra bersumber dari sensor **Multispectral Instrument (MSI)** pada satelit **Sentinel-2** dalam produk **Level-2A** (koreksi atmosfer *Bottom-of-Atmosphere*), diakses melalui platform **openEO** pada *Copernicus Data Space Ecosystem* (CDSE).

| Band    | Nama                      | Panjang Gelombang | Resolusi | Kegunaan                                                      |
| ------- | ------------------------- | ----------------- | -------- | ------------------------------------------------------------- |
| **B02** | Blue                      | 490 nm            | 10 m     | Deteksi badan air dan hamburan atmosfer                       |
| **B03** | Green                     | 560 nm            | 10 m     | Puncak pantulan klorofil dan sedimen perairan                 |
| **B04** | Red                       | 665 nm            | 10 m     | Serapan klorofil; pembeda vegetasi dengan tanah dan bangunan  |
| **B08** | Near Infrared (NIR)       | 842 nm            | 10 m     | Pantulan struktur daun; diserap hampir total oleh air         |
| **B11** | Short-Wave Infrared (SWIR)| 1610 nm           | 20 m     | Kelembapan tanah dan vegetasi serta material beton/atap       |

### 2.3. Indeks Spektral

Empat indeks spektral dihitung untuk memperkuat keterpisahan antar-kelas (konstanta $\epsilon$ kecil mencegah pembagian dengan nol):

**Normalized Difference Vegetation Index (NDVI)**, mengukur kerapatan vegetasi hijau:

$$\text{NDVI} = \frac{B08 - B04}{B08 + B04 + \epsilon}$$

**Normalized Difference Water Index (NDWI)**, mengisolasi badan air terbuka:

$$\text{NDWI} = \frac{B03 - B08}{B03 + B08 + \epsilon}$$

**Modified NDWI (MNDWI)**, mendeteksi air dengan SWIR dan meredam gangguan area terbangun:

$$\text{MNDWI} = \frac{B03 - B11}{B03 + B11 + \epsilon}$$

**Normalized Difference Built-up Index (NDBI)**, menonjolkan kawasan terbangun:

$$\text{NDBI} = \frac{B11 - B08}{B11 + B08 + \epsilon}$$

### 2.4. Dataset Ground Truth

Sampel *ground truth* berupa **poligon yang didigitasi** di atas citra satelit resolusi tinggi dan disimpan dalam format **GeoJSON** (EPSG:4326). Setiap poligon memiliki label kelas, dan sampel sengaja disebar di berbagai wilayah Jawa Timur agar model tidak hanya mengenali ciri satu lokasi.

| Kelas         | Jumlah Poligon |
| ------------- | -------------- |
| **Bangunan**  | 73             |
| **Pertanian** | 74             |
| **Air**       | 75             |
| **Hutan**     | 121            |
| **Mangrove**  | 75             |
| **Total**     | **418**        |

### 2.5. Akuisisi Citra via openEO

Citra diunduh melalui openEO dengan koleksi `SENTINEL2_L2A`. Karena sampel tersebar luas, pengunduhan dilakukan **per wilayah** (satu *bounding box* untuk setiap kelompok poligon yang berdekatan) agar berkas tetap ringan dan tidak melampaui batas pemrosesan. Citra dikomposit dengan **median temporal** untuk meminimalkan pengaruh awan.

| Parameter           | Nilai                    |
| ------------------- | ------------------------ |
| Koleksi             | `SENTINEL2_L2A`          |
| Periode citra       | 1 September 2026 – 30 September 2026   |
| Batas tutupan awan  | 30 %                   |
| Resolusi            | 10 m                  |
| Format keluaran     | GeoTIFF (`.tif`)         |

---

## 3. Data Preprocessing (Pra-pemrosesan Data)

### 3.1. Ekstraksi Piksel dari Poligon

Citra GeoTIFF dipotong menggunakan bentuk setiap poligon sampel (`rasterio.mask`), dan seluruh piksel di dalamnya diambil sebagai data. Piksel kosong (bernilai 0) dibuang. Proses ini menghasilkan **3.402.010 piksel** berlabel.

### 3.2. Kompresi Spasial (Piksel → Poligon)

Piksel yang bertetangga dalam satu poligon memiliki nilai spektral yang sangat mirip (autokorelasi spasial). Jika piksel-piksel ini dipakai langsung dan dibagi acak, piksel dari poligon yang sama dapat masuk ke data latih dan data uji sekaligus sehingga akurasi menjadi terlalu optimistis. Karena itu seluruh piksel dalam satu poligon dipadatkan menjadi **satu sampel**.

| Tahap                    | Jumlah Data                |
| ------------------------ | -------------------------- |
| Piksel hasil ekstraksi   | **3.402.010** piksel       |
| Setelah kompresi spasial | **418** poligon            |

Kompresi ini juga mencegah poligon berukuran besar mendominasi proses pelatihan.

### 3.3. Fitur Tekstur Spasial

Setiap poligon dideskripsikan oleh **18 fitur tekstur spasial** yang diturunkan dari 5 band asli (B02, B03, B04, B08, B11) dan 4 indeks spektral (NDVI, NDWI, MNDWI, NDBI). Fitur tekstur menangkap tidak hanya nilai rata-rata, tetapi juga variasi nilai di dalam poligon, yang membedakan permukaan homogen (misalnya air) dari permukaan heterogen (misalnya permukiman).

[ISI: sebutkan 18 fitur yang dipakai, misalnya statistik yang dihitung per band atau indeks]

### 3.4. Pengelompokan Wilayah untuk Validasi

Poligon dikelompokkan menjadi **wilayah** menggunakan algoritma **DBSCAN** pada titik pusat poligon (dalam sistem koordinat meter). Poligon yang berdekatan masuk ke wilayah yang sama dan selalu berada pada fold yang sama saat validasi.

| Parameter           | Nilai                  |
| ------------------- | ---------------------- |
| Algoritma           | DBSCAN                 |
| Radius (`eps`)      | 10.0 km               |
| Jumlah wilayah      | 27                  |

Radius dipilih secara struktural: cukup besar untuk memisahkan poligon yang bertetangga, tetapi tidak sampai menyatukan sebagian besar sampel menjadi satu wilayah.

---

## 4. Modeling (Pemodelan Machine Learning)

### 4.1. Algoritma Random Forest

**Random Forest** adalah algoritma *ensemble* yang membangun banyak pohon keputusan dari subset data dan subset fitur yang berbeda, lalu menentukan kelas akhir melalui pemungutan suara mayoritas. Algoritma ini dipilih karena:

1. **Tidak memerlukan standardisasi fitur**, sehingga band mentah dan indeks dapat dipakai bersama.
2. **Tahan terhadap *outlier* dan *overfitting*** dibanding satu pohon keputusan, cocok untuk data berukuran menengah (418 poligon).
3. **Menangani hubungan non-linear** antar-fitur spektral dan tekstur.
4. **Menyediakan *feature importance*** untuk menafsirkan fitur yang paling berperan.

### 4.2. Konfigurasi Model

| Hyperparameter     | Nilai   |
| ------------------ | ------- |
| `n_estimators`     | 200   |
| `min_samples_leaf` | 2   |
| `class_weight`     | balanced   |
| `random_state`     | 42   |

### 4.3. Ekspor Model

Setelah evaluasi, model final dilatih ulang pada **seluruh data poligon** dan diekspor sebagai berkas biner `model_LULC_jatim_texture.joblib` agar dapat dimuat kembali oleh aplikasi Streamlit tanpa pelatihan ulang.

---

## 5. Evaluation (Evaluasi Model & Hasil Klasifikasi)

### 5.1. Skema Validasi Antar-Wilayah

Evaluasi memakai **validasi silang berbasis wilayah**: seluruh poligon dari satu wilayah selalu berada pada fold yang sama, sehingga model diuji pada lokasi yang **belum pernah dilihat** saat pelatihan. Skema ini lebih ketat daripada pembagian acak karena autokorelasi spasial tidak lagi "bocor" dari data latih ke data uji.

### 5.2. Hasil Evaluasi

**Akurasi Validasi Wilayah: 75,84%**

| Kelas         | F1-Score | Kategori     | Keterangan                                                    |
| ------------- | -------- | ------------ | ------------------------------------------------------------- |
| **Bangunan**  | 0,95     | Sangat baik  | Ciri spektral khas (SWIR tinggi, NDBI tinggi)                 |
| **Air**       | 0,88     | Sangat baik  | Penyerapan NIR dan SWIR membedakannya dari daratan            |
| **Mangrove**  | 0,77     | Baik         | Dapat dipisahkan dari hutan daratan berkat sinyal kelembapan  |
| **Hutan**     | 0,74     | Baik         | Sebagian tertukar dengan vegetasi lain                        |
| **Pertanian** | 0,47     | Rendah       | Kelas terlemah; ciri berubah mengikuti fase tanam             |

### 5.3. Confusion Matrix

Matriks kekeliruan lengkap dan grafik Precision, Recall, serta F1-Score per kelas ditampilkan secara interaktif pada dashboard Streamlit.

## 5.3. Confusion Matrix

| Aktual \ Prediksi | Bangunan | Pertanian | Air | Hutan | Mangrove | Total Aktual |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Bangunan** | 71 | 1 | 0 | 1 | 0 | **73** |
| **Pertanian** | 4 | 34 | 5 | 25 | 6 | **74** |
| **Air** | 0 | 8 | 63 | 4 | 0 | **75** |
| **Hutan** | 2 | 16 | 0 | 96 | 7 | **121** |
| **Mangrove** | 0 | 10 | 0 | 12 | 53 | **75** |


### 5.4. Analisis Hasil

1. **Bangunan dan Air** memiliki kinerja tertinggi (F1 ≥ 0,88) karena memiliki ciri spektral yang sangat berbeda dari kelas lain.
2. **Mangrove (0,77) dan Hutan (0,74)** cukup baik. Fitur tekstur dan indeks kelembapan membantu memisahkan vegetasi pesisir dari hutan daratan.
3. **Pertanian (0,47)** adalah kelas terlemah. Diduga karena lahan pertanian melewati beberapa fase (genangan, tanam, hijau, panen) yang membuatnya mirip dengan kelas lain pada satu komposit waktu, terutama vegetasi. Dugaan ini perlu diuji dengan citra multi-waktu.
4. Hasil dilaporkan dari **validasi antar-wilayah** sehingga cenderung lebih rendah dibanding evaluasi acak per piksel, tetapi lebih mencerminkan kinerja pada lokasi baru.

### 5.5. Riwayat Iterasi

| Iterasi    | Jumlah Poligon | Fitur                                    | Hasil Validasi Wilayah                        |
| ---------- | -------------- | ---------------------------------------- | --------------------------------------------- |
| **Awal**   | 366            | 9 fitur spektral (rata-rata per poligon) | 64,92% (rata-rata per fold), 68% (gabungan)   |
| **Final**  | 418            | 18 fitur tekstur spasial                 | **75,84%**                                    |

Pada iterasi awal, analisis per fold menunjukkan akurasi yang tidak stabil: satu fold hanya 31,6% karena hampir seluruh isinya poligon hutan, dan sampel hutan terkumpul di sedikit wilayah. Temuan ini menjadi dasar penambahan sampel dan pengayaan fitur pada iterasi final. Kedua hasil tidak sepenuhnya sebanding karena komposisi fold dan jumlah sampelnya berbeda.

---

## 6. Deployment (Penyebaran Model via Streamlit)

### 6.1. Arsitektur Aplikasi

Model dan hasil evaluasi dipublikasikan sebagai ***Single-Page Application* (SPA)** interaktif berbasis **Streamlit**. Seluruh konten berada dalam satu halaman sehingga pengguna dapat melihat peta, filter, dan grafik tanpa berpindah halaman.

| Komponen          | Keterangan                                                                              |
| ----------------- | --------------------------------------------------------------------------------------- |
| **Peta**          | **Folium** (Leaflet) dengan basemap *Google Satellite* dan *OpenStreetMap*              |
| **Filter kelas**  | Filter native melalui `FeatureGroup`; tiap kelas lahan dapat dicentang atau dihapus centangnya |
| **Navigasi peta** | *Zoom* dan *pan*                                                                        |
| **Grafik**        | **Plotly**: *Confusion Matrix* dan bar chart horizontal Precision, Recall, F1-Score     |
| **Model**         | `model_LULC_jatim_texture.joblib`                                                       |

### 6.2. Fitur Interaktif Peta

- **Basemap satelit** memungkinkan hasil klasifikasi dibandingkan langsung dengan kenampakan lahan sebenarnya.
- **Filter per kelas** (misalnya hanya menampilkan Pertanian) memudahkan pengguna menelusuri satu jenis tutupan lahan.
- **Warna per kelas** konsisten pada peta dan grafik sehingga mudah dibaca.

### 6.3. Akses Publik

Aplikasi dapat diakses secara publik melalui tautan berikut:

🌐 **<https://dashboard-lulc-jatim.streamlit.app/>**


## 7. Kesimpulan

1. **Hasil utama.** Model Random Forest dengan 18 fitur tekstur spasial mencapai **akurasi validasi wilayah 75,84%** untuk 5 kelas tutupan lahan di Jawa Timur. Angka ini diperoleh dari pengujian pada lokasi yang belum pernah dilihat model.
2. **Kinerja per kelas.** Bangunan (F1 0,95) dan Air (F1 0,88) terklasifikasi sangat baik, Mangrove (0,77) dan Hutan (0,74) cukup baik, sedangkan **Pertanian (0,47)** masih menjadi kelas yang perlu ditingkatkan.
3. **Pentingnya validasi spasial.** Kompresi piksel menjadi poligon dan validasi antar-wilayah mencegah kebocoran data spasial. Analisis per fold juga terbukti membantu menemukan ketimpangan sebaran sampel.
4. **Deployment.** Hasil dipublikasikan dalam dashboard Streamlit interaktif yang memungkinkan pemantauan tutupan lahan secara visual oleh pengguna umum.

