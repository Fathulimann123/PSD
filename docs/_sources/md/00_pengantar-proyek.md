## Business Understanding

### Mengamati Kualitas Udara

**Apa itu Indeks Kualitas Udara (Air Quality Index)?**

Indeks Kualitas Udara (AQI) adalah angka yang meringkas kondisi pencemaran udara di suatu wilayah pada waktu tertentu menjadi satu skala yang mudah dipahami. AQI dihitung dari konsentrasi beberapa polutan udara utama, lalu dikonversi jadi kategori seperti "Baik", "Sedang", "Tidak Sehat", hingga "Berbahaya". Semakin tinggi nilai AQI, semakin besar risiko kesehatan yang ditimbulkan bagi manusia mulai dari gangguan pernapasan ringan sampai penyakit kronis pada paparan jangka panjang.

**Unsur-unsur yang menyebabkan baik/buruknya kualitas udara**

Kualitas udara ditentukan oleh konsentrasi gas-gas polutan yang terkandung di atmosfer, bersumber dari aktivitas manusia (kendaraan bermotor, industri, pertanian) maupun alami (kebakaran lahan, aktivitas vulkanik). Pada tugas ini, pengamatan difokuskan pada empat polutan yang tersedia datanya lewat satelit Sentinel-5P:

- **NO2 (Nitrogen Dioksida)** - dihasilkan terutama dari pembakaran bahan bakar fosil: kendaraan bermotor, pembangkit listrik, dan aktivitas industri. Konsentrasi tinggi berasosiasi dengan gangguan pernapasan, memperburuk asma/bronkitis, dan berkontribusi pada pembentukan hujan asam serta ozon troposfer.
- **CO (Karbon Monoksida)** - gas hasil pembakaran tidak sempurna, sumbernya mirip NO2 (kendaraan, industri) ditambah kebakaran lahan/hutan. Berbahaya karena mengikat hemoglobin darah lebih kuat dibanding oksigen, sehingga mengganggu distribusi oksigen ke seluruh tubuh.
- **SO2 (Sulfur Dioksida)** - dihasilkan dari pembakaran bahan bakar fosil yang mengandung sulfur, terutama industri dan pembangkit listrik tenaga batu bara. Konsentrasi tinggi menyebabkan iritasi saluran pernapasan dan merupakan penyebab utama hujan asam.
- **CH4 (Metana)** - gas rumah kaca yang berasal dari aktivitas pertanian (sawah, peternakan), pembusukan sampah organik (TPA), dan kebocoran gas alam. Tidak berbahaya langsung bagi pernapasan seperti tiga polutan lainnya, tetapi berkontribusi besar terhadap pemanasan global dan menjadi indikator aktivitas biogenik/pertanian di suatu wilayah.

**Sumber data**

Data diperoleh dari citra satelit **Sentinel-5P (TROPOMI)**, bagian dari program Copernicus milik European Space Agency (ESA), yang secara khusus dirancang untuk memantau komposisi atmosfer bumi termasuk gas-gas polutan di atas. Satelit ini menyediakan data harian dengan cakupan global, diakses melalui **Copernicus Data Space Ecosystem**.

**Wilayah dan tujuan pengamatan**

Tugas ini bertujuan untuk mengamati dan memvisualisasikan tren konsentrasi NO2, CO, SO2, dan CH4 di wilayah **Bangkalan, Burneh, Madura** selama periode satu tahun, yaitu **24 Agustus 2025 s.d. 24 Agustus 2026**, guna memahami pola fluktuasi kualitas udara di wilayah tersebut sepanjang waktu — apakah cenderung stabil, musiman, atau ada tren kenaikan/penurunan tertentu. Wilayah pengamatan ditentukan dalam bentuk bounding box (koordinat 112.70–112.80 BT, -7.10 s.d. -7.00 LS), divisualisasikan pada peta dasar OpenStreetMap menggunakan QGIS sebagai bagian dari tahap ini.

**Sumber data**

Data diperoleh dari citra satelit **Sentinel-5P (TROPOMI)**, bagian dari program Copernicus milik European Space Agency (ESA), yang secara khusus dirancang untuk memantau komposisi atmosfer bumi termasuk gas-gas polutan di atas. Satelit ini menyediakan data harian dengan cakupan global, diakses melalui **Copernicus Data Space Ecosystem**.

**Tujuan pengamatan**

Tugas ini bertujuan untuk mengamati dan memvisualisasikan tren konsentrasi NO2 dan CO di wilayah **Bangkalan, Burneh** selama periode satu tahun, yaitu **24 Agustus 2025 s.d. 24 Agustus 2026**, guna memahami pola fluktuasi kualitas udara di wilayah tersebut sepanjang waktu,  apakah cenderung stabil, musiman, atau ada tren kenaikan/penurunan tertentu.

## Data Understanding

### Collecting / Mengumpulkan Data dari Copernicus Data Space

Data kualitas udara diperoleh dari citra satelit Sentinel-5P (TROPOMI) melalui **Copernicus Data Space Ecosystem**, diakses menggunakan library `openeo` di Python (dijalankan di Google Colab). Empat polutan diamati: **NO2, CO, SO2, dan CH4**, untuk wilayah **Bangkalan, Burneh, ** dalam rentang waktu **24 Agustus 2025 s.d. 24 Agustus 2026**.

![Peta Kota](../img/udara/folium.png)

Wilayah pengamatan (AOI) ditentukan lewat geojson.io (bounding box: 112.70–112.80 BT, -7.10 s.d. -7.00 LS), lalu divisualisasikan resmi di QGIS sebagai bagian Business Understanding.

```python
!pip install openeo netCDF4

import openeo
connection = openeo.connect("openeo.dataspace.copernicus.eu")
connection.authenticate_oidc()

bbox = {"west": 112.70, "south": -7.10, "east": 112.80, "north": -7.00}
periode = ["2025-08-24", "2026-08-24"]

polutan_list = ["NO2", "CO", "SO2", "CH4"]
for p in polutan_list:
    cube = connection.load_collection(
        "SENTINEL_5P_L2", temporal_extent=periode, spatial_extent=bbox, bands=[p]
    )
    cube_daily = cube.aggregate_temporal_period(reducer="mean", period="day")
    cube_daily.execute_batch(title=f"{p} crawl", outputfile=f"{p}.nc")
```

### Membaca Data & Melaporkan Kondisi Aslinya

Data NetCDF dibaca apa adanya (grid harian dirata-ratakan spasial pakai `np.nanmean`, tanpa interpolasi) agar kondisi data termasuk bagian yang hilang bisa dilaporkan dulu sebelum masuk tahap pembersihan di Data Preparation.

```python
import netCDF4, numpy as np, pandas as pd

def nc_to_daily_raw(nc_path, band):
    ds = netCDF4.Dataset(nc_path)
    raw = ds.variables[band][:]
    time = ds.variables["t"][:]
    dates = netCDF4.num2date(time, units=ds.variables["t"].units)
    filled = raw.astype(np.float64).filled(np.nan)
    daily_dates = [d.strftime("%Y-%m-%d") for d in dates]
    daily_values = [float(np.nanmean(filled[i])) for i in range(filled.shape[0])]
    df = pd.DataFrame({"date": daily_dates, band: daily_values})
    df["date"] = pd.to_datetime(df["date"])
    return df.set_index("date")

df_no2 = nc_to_daily_raw("NO2.nc", "NO2")
df_co  = nc_to_daily_raw("CO.nc", "CO")
df_so2 = nc_to_daily_raw("SO2.nc", "SO2")
df_ch4 = nc_to_daily_raw("CH4.nc", "CH4")
```

**Identifikasi missing value:**

| Polutan | Hari Kosong | Total Hari Tercatat | Persentase |
|---|---|---|---|
| NO2 | 157 | 363 | 43.3% |
| CO | 142 | 365 | 38.9% |
| SO2 | 111 | 361 | 30.7% |
| CH4 | 197 | 214 | 92.1% |

Seluruh polutan menunjukkan proporsi data kosong yang cukup tinggi, dengan CH4 paling ekstrem (92.1%). Ini konsisten dengan karakteristik sensor Sentinel-5P yang sensitif terhadap tutupan awan dan khusus CH4, syarat kualitas datanya (kanal SWIR) jauh lebih ketat dibanding tiga polutan lain, sehingga cakupan datanya pun jauh lebih jarang (hanya 214 dari ~366 hari kalender yang bahkan tercatat sama sekali).

Sebagai catatan tambahan, nilai SO2 dan sebagian kecil NO2 mengandung angka negatif (SO2: 92 dari 250 nilai valid, NO2: 2 dari 206 nilai valid). Ini bukan kesalahan pembacaan nilai negatif pada retrieval atmosfer Sentinel-5P adalah hal umum yang muncul akibat noise instrumen ketika konsentrasi polutan sesungguhnya sangat rendah/mendekati nol, bukan indikasi bahwa terdapat "polutan minus" secara fisik.

### Eksplorasi Data - Peta

Peta interaktif (folium, basemap OpenStreetMap) menampilkan batas AOI dan ringkasan rata-rata keempat polutan dalam satu popup:

![Peta burneh](../img/udara/folium.png)

```python
import folium

center = [(bbox["south"] + bbox["north"]) / 2, (bbox["west"] + bbox["east"]) / 2]
peta = folium.Map(location=center, zoom_start=11, tiles="OpenStreetMap")

folium.Rectangle(
    bounds=[[bbox["south"], bbox["west"]], [bbox["north"], bbox["east"]]],
    color="red", fill=True, fill_opacity=0.1, tooltip="Area of Interest (AOI)",
).add_to(peta)

popup_text = f"""
Wilayah: Bangkalan, Burneh<br>
Periode: 24 Agustus 2025 - 24 Agustus 2026<br>
Rata-rata NO2: {df_no2['NO2'].mean():.6f}<br>
Rata-rata CO: {df_co['CO'].mean():.6f}<br>
Rata-rata SO2: {df_so2['SO2'].mean():.6f}<br>
Rata-rata CH4: {df_ch4['CH4'].mean():.6f}
"""
folium.Marker(location=center, popup=popup_text, tooltip="Ringkasan Kualitas Udara").add_to(peta)
peta.save("peta_kualitas_udara.html")
peta
```

Popup menampilkan ringkasan: rata-rata NO2 0.000028, CO 0.028745, SO2 0.000050, CH4 1879.92 (satuan CH4 jauh lebih besar dibanding tiga polutan lain karena diukur dalam ppb, bukan mol/m²).

### Eksplorasi Data - Grafik & CSV per Polutan

![grafik no2](../img/udara/no2.png)

**NO2** (rentang nilai: -0.0000052 s.d. 0.0000835, rata-rata 0.000028 mol/m²), sumber utamanya bersifat harian/rutin (kendaraan bermotor, industri).

```python
import matplotlib.pyplot as plt
plt.figure(figsize=(12, 4))
plt.plot(df_no2.index, df_no2["NO2"], linewidth=1)
plt.title("Konsentrasi NO2 Harian (24 Agst 2025 - 24 Agst 2026)")
plt.xlabel("Tanggal"); plt.ylabel("NO2 (mol/m²)")
plt.tight_layout(); plt.show()
df_no2.to_csv("no2_daily.csv")
```
![grafik co](../img/udara/co.png)

**CO** (rentang nilai: 0.0205 s.d. 0.0469, rata-rata 0.0287 mol/m², tidak ada nilai negatif), diamati untuk menangkap lonjakan akibat pembakaran tidak sempurna.

```python
plt.figure(figsize=(12, 4))
plt.plot(df_co.index, df_co["CO"], linewidth=1, color="darkorange")
plt.title("Konsentrasi CO Harian (24 Agst 2025 - 24 Agst 2026)")
plt.xlabel("Tanggal"); plt.ylabel("CO (mol/m²)")
plt.tight_layout(); plt.show()
df_co.to_csv("co_daily.csv")
```

![grafik so2](../img/udara/so2.png)

**SO2** (rentang nilai: -0.00156 s.d. 0.00099, rata-rata 0.00005 mol/m², sebagian besar nilai berada di sekitar nol), sumbernya berbeda dari NO2/CO (industri, pembangkit listrik batu bara).

```python
plt.figure(figsize=(12, 4))
plt.plot(df_so2.index, df_so2["SO2"], linewidth=1, color="green")
plt.title("Konsentrasi SO2 Harian (24 Agst 2025 - 24 Agst 2026)")
plt.xlabel("Tanggal"); plt.ylabel("SO2 (mol/m²)")
plt.tight_layout(); plt.show()
df_so2.to_csv("so2_daily.csv")
```
![grafik ch4](../img/udara/ch4.png)

**CH4** (rentang nilai: 1785 s.d. 1913 ppb, rata-rata 1880 ppb), data paling jarang (92.1% kosong) sehingga grafiknya tampak terputus-putus; karakteristik sumbernya (pertanian, TPA, kebocoran gas alam) berbeda dari tiga polutan lain.

```python
plt.figure(figsize=(12, 4))
plt.plot(df_ch4.index, df_ch4["CH4"], linewidth=1, color="purple")
plt.title("Konsentrasi CH4 Harian (24 Agst 2025 - 24 Agst 2026)")
plt.xlabel("Tanggal"); plt.ylabel("CH4 (ppb)")
plt.tight_layout(); plt.show()
df_ch4.to_csv("ch4_daily.csv")
```
![gabungan dari 4 polutan](../img/udara/polutan1.png)


# Tugas - Pertemuan 2

## 1. Memindahkan Data CSV ke Cloud (Aiven PostgreSQL)

Empat file CSV hasil crawling Sentinel-5P dari tugas sebelumnya (`no2_daily.csv`, `co_daily.csv`, `so2_daily.csv`, `ch4_daily.csv`) dipindahkan ke database PostgreSQL yang di-*host* di **Aiven** (console.aiven.io), agar data tersimpan secara terpusat di cloud dan bisa diakses dari alat lain (KNIME) tanpa perlu menyalin file secara manual.

**Membuat service PostgreSQL di Aiven:**

Service PostgreSQL dibuat lewat console.aiven.io (Create service -> PostgreSQL -> plan Hobbyist/Free). Setelah status menjadi "Running", Aiven menyediakan Service URI berisi kredensial koneksi (host, port, user, password, nama database).

**Mengirim data dari Python (Google Colab) ke PostgreSQL:**

```python
!pip install sqlalchemy psycopg2-binary

import pandas as pd
from sqlalchemy import create_engine

connection_string = "postgresql://avnadmin:[password]@pg-110e932c-psd1-6fc0.f.aivencloud.com:13017/defaultdb?sslmode=require"
engine = create_engine(connection_string)

files = {
    "no2_daily.csv": "no2",
    "co_daily.csv": "co",
    "so2_daily.csv": "so2",
    "ch4_daily.csv": "ch4",
}

for fname, table_name in files.items():
    df = pd.read_csv(fname)
    df.to_sql(table_name, engine, if_exists="replace", index=False)
    print(f"{table_name} berhasil dikirim, {len(df)} baris")
```

`sqlalchemy` dipakai sebagai jembatan antara pandas dan PostgreSQL, sementara `psycopg2-binary` adalah driver yang menerjemahkan perintah Python menjadi protokol yang dipahami PostgreSQL. Fungsi `to_sql()` otomatis membuat tabel baru (jika belum ada) dan mengisi seluruh baris CSV ke dalamnya `if_exists="replace"` memastikan tabel ditimpa dengan data terbaru setiap kali skrip dijalankan ulang, sehingga tidak terjadi duplikasi data.

**Hasil:**

| Tabel | Jumlah Baris |
|---|---|
| `no2` | 363 |
| `co` | 365 |
| `so2` | 361 |
| `ch4` | 214 |

**Verifikasi:**

Data yang sudah masuk diverifikasi langsung lewat fitur **PG Studio** pada console Aiven (query editor bawaan), dengan menjalankan:


```sql
SELECT COUNT(*) FROM no2;
SELECT COUNT(*) FROM co;
SELECT COUNT(*) FROM so2;
SELECT COUNT(*) FROM ch4;
```

Jumlah baris yang muncul di database cocok dengan jumlah baris pada file CSV asli, menandakan seluruh data berhasil dipindahkan tanpa ada yang hilang atau terpotong.

![sql-aiven](../img/udara/my-collage.png)

## 2. Menarik Data dari Cloud ke KNIME

Keempat tabel polutan (no2, co, so2, ch4) digabungkan terlebih dahulu menjadi satu tabel bernama polutan, agar dapat ditarik dan dianalisis sekaligus dalam satu alur kerja KNIME.
 

``` 
CREATE TABLE polutan AS
WITH all_dates AS (
    SELECT date FROM no2
    UNION SELECT date FROM co
    UNION SELECT date FROM so2
    UNION SELECT date FROM ch4
)
SELECT 
    d.date, no2."NO2", co."CO", so2."SO2", ch4."CH4"
FROM all_dates d
LEFT JOIN no2 ON d.date = no2.date
LEFT JOIN co ON d.date = co.date
LEFT JOIN so2 ON d.date = so2.date
LEFT JOIN ch4 ON d.date = ch4.date
ORDER BY d.date;
 ```
Tabel gabungan ini memiliki 365 baris (gabungan seluruh tanggal unik dari keempat tabel sumber).
 
![node knime](../img/udara/node-knime.png)

Alur kerja KNIME:
 
1. PostgreSQL Connector - menghubungkan KNIME ke server Aiven (host, port, database, kredensial user).
2. DB Table Selector - memilih tabel polutan (skema public).
3. DB Reader - menarik seluruh 365 baris ke dalam memori KNIME.
4. Statistics - menghitung metrik statistik deskriptif untuk setiap kolom polutan.

## 3. Penjelasan Properti Statistik KNIME
![statistik knime](../img/udara/statistik-knime.png)
Hasil node Statistics menampilkan ringkasan untuk 4 variabel polutan:

| Properti | NO2 | CO | SO2 | CH4 |
|---|---|---|---|---|
| No. Missing | 159 | 142 | 115 | 348 |
| Min | -5.186 | 20487.351 | -1563.039 | 1785.148 |
| Max | 83.522 | 46903.509 | 986.825 | 1912.545 |
| Mean | 28.035 | 28744.913 | 49.954 | 1879.925 |
| Std. Deviation | 14.624 | 3456.361 | 223.781 | 35.7 |
| Sum | 5775.255 | 6410115.688 | 12488.495 | 31958.717 |
| Skewness | 0.513 | 0.777 | -1.277 | -1.265 |
| Kurtosis | 0.89 | 2.777 | 11.745 | 1.911 |

**Column** - nama variabel/kolom yang datanya sedang diringkas (di sini: NO2, CO, SO2, CH4).

**Min & Max** - nilai terendah dan tertinggi yang tercatat pada suatu kolom. Contoh: SO2 memiliki rentang paling lebar (-1563.039 s.d. 986.825), menandakan fluktuasi harian yang cukup ekstrem dibanding polutan lain.

**Mean** - nilai rata-rata seluruh data valid pada kolom tersebut, dihitung dengan menjumlahkan seluruh nilai lalu membaginya dengan jumlah data yang tidak kosong.

**Median** - nilai tengah data setelah diurutkan (50% data berada di bawahnya, 50% di atasnya). Node Statistics KNIME tidak menampilkan nilai ini secara langsung (keterbatasan bawaan node), sehingga dihitung manual melalui query:

```
SELECT 
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "NO2") AS median_no2,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "CO") AS median_co,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "SO2") AS median_so2,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "CH4") AS median_ch4
FROM polutan;
```

**Std. Deviation (Standar Deviasi)** - mengukur seberapa jauh rata-rata sebaran data dari nilai Mean-nya. Semakin tinggi nilainya, semakin lebar fluktuasi datanya. SO2 (223.781) jauh lebih fluktuatif dibanding CH4 (35.7) yang relatif stabil.

**Variance** - kuadrat dari Standar Deviasi, mengukur besaran sebaran data dalam satuan kuadrat.

**Skewness** - mengukur kemencengan/asimetri distribusi data terhadap Mean-nya.
- Skewness ≈ 0 → distribusi simetris
- Skewness > 0 → ekor memanjang ke kanan (nilai ekstrem tinggi lebih sering muncul), contoh: CO (0.777)
- Skewness < 0 → ekor memanjang ke kiri, contoh: SO2 (-1.277), CH4 (-1.265)

**Kurtosis** - mengukur ketajaman puncak dan ketebalan ekor distribusi, menunjukkan seberapa ekstrem outlier dalam data.
- Kurtosis ≈ 0 → distribusi normal
- Kurtosis > 0 → puncak tajam, ekor tebal (banyak outlier ekstrem) — SO2 (11.745) paling menonjol, menandakan banyak nilai pencilan ekstrem di kedua arah
- Kurtosis < 0 → puncak datar

**No. Missing** - jumlah sel kosong (NULL) akibat data tidak terekam pada tanggal tertentu (umumnya karena tutupan awan saat satelit melintas). CH4 memiliki proporsi missing tertinggi (348 dari 365 hari) karena syarat kualitas data yang lebih ketat pada sensor SWIR.

**No. NaNs / No. +infinite / No. -infinite** - masing-masing menghitung jumlah entri yang bernilai "Not a Number" (hasil pembagian tidak terdefinisi) dan nilai tak terhingga positif/negatif. Pada data ini, ketiganya bernilai 0 untuk seluruh polutan - menandakan tidak ada anomali komputasi selain missing value biasa.

**Overall Sum** - jumlah keseluruhan nilai pada kolom tersebut.

**Row count** - jumlah total baris dalam tabel (365, mencakup seluruh rentang tanggal 24 Agustus 2025–24 Agustus 2026).



## 4. Contoh Perhitungan Manual

Contoh perhitungan manual berikut menggunakan kolom **NO2** (n = 206 data valid, setelah dikurangi 159 missing value dari total 365 hari).

### Mean

$$ \bar{x} = \frac{\sum_{i=1}^{n} x_i}{n} $$

```
n     = 206
Sum   = 5775.255
Mean  = 5775.255 / 206
Mean  = 28.035
```

### Median

Urutkan seluruh 206 data dari terkecil ke terbesar. Karena n = 206 (genap), Median adalah rata-rata dari 2 data di tengah (data ke-103 dan ke-104):

$$ Median = \frac{X_{n/2} + X_{(n/2)+1}}{2} $$

```
X_103  = 26.853
X_104  = 27.027
Median = (26.853 + 27.027) / 2
Median = 26.940
```

### Standar Deviasi (Sampel)

$$ s = \sqrt{\frac{\sum_{i=1}^{n} (x_i - \bar{x})^2}{n-1}} $$

```
Mean = 28.035
n - 1 = 205
Σ(xi - Mean)² = 43591.72   (jumlah kuadrat selisih tiap data ke rata-rata)
s = √(43591.72 / 205)
s = √212.642
s = 14.624
```

### Variance

Variance adalah kuadrat dari Standar Deviasi:

```
Variance = s²
Variance = 14.624²
Variance = 213.873
```

### Skewness (Fisher-Pearson, Sampel)

$$ Skewness = \frac{n}{(n-1)(n-2)} \sum_{i=1}^{n} \left(\frac{x_i - \bar{x}}{s}\right)^3 $$

```
A = n / [(n-1)(n-2)]
A = 206 / (205 × 204)
A = 206 / 41820
A = 0.004926

B = Σ [(xi - 28.035) / 14.624]³
B = 105.65   (jumlah dari 206 suku pangkat tiga)

Skewness = A × B
Skewness = 0.004926 × 105.65
Skewness = 0.520
```

Nilai positif (0.520) menunjukkan distribusi NO2 sedikit menceng ke kanan — ada beberapa hari dengan konsentrasi jauh lebih tinggi dari rata-rata (lihat Max = 83.522, jauh di atas Mean = 28.035), sementara nilai rendah lebih rapat di sekitar Mean.

### Kurtosis (Excess, Sampel)

$$ Kurtosis = \left[ \frac{n(n+1)}{(n-1)(n-2)(n-3)} \sum \left(\frac{x_i - \bar{x}}{s}\right)^4 \right] - \frac{3(n-1)^2}{(n-2)(n-3)} $$

```
A = n(n+1) / [(n-1)(n-2)(n-3)]
A = 206 × 207 / (205 × 204 × 203)
A = 42642 / 8489260
A = 0.005024

B = Σ [(xi - 28.035) / 14.624]⁴
B = 761.3

C = 3(n-1)² / [(n-2)(n-3)]
C = 3 × 205² / (204 × 203)
C = 126075 / 41412
C = 3.044

Kurtosis = (A × B) - C
Kurtosis = (0.005024 × 761.3) - 3.044
Kurtosis = 3.824 - 3.044
Kurtosis = 0.890
```

Nilai mendekati 0 (0.890, sedikit di atas normal) menunjukkan distribusi NO2 relatif mesokurtik — tidak ada outlier ekstrem yang berlebihan, berbeda dengan SO2 yang kurtosisnya jauh lebih tinggi (11.745), menandakan SO2 memiliki lebih banyak nilai pencilan ekstrem.

### Overall Sum

$$ Sum = \sum_{i=1}^{n} x_i $$

```
Sum = 23.906 + 18.914 + 47.359 + 53.037 + 17.220 + ... (206 nilai)
Sum = 5775.255
```
# Tugas Pertemuan 3 

## 1. Perubahan Cakupan Wilayah

Sebagai tindak lanjut instruksi tugas terbaru, cakupan wilayah dipersempit dari tingkat kabupaten (Bangkalan) menjadi tingkat **kecamatan (Burneh)**, dengan syarat wilayah harus unik dan tidak sama dengan yang dipakai mahasiswa lain. Analisis juga dipersempit hanya pada satu polutan, yaitu **CO (Karbon Monoksida)**.

Wilayah kecamatan Burneh direpresentasikan menggunakan polygon (bukan sekadar bounding box kotak) agar cakupan spasialnya lebih presisi mengikuti bentuk asli kecamatan:

![burneh](../img/udara/burneh.png)

```python
geojson_data = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "Kecamatan Burneh"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [112.7752359, -7.0296739],
            [112.7753502, -7.0574764],
            [112.7918155, -7.0574764],
            [112.8101103, -7.0582708],
            [112.8091829, -7.0303462],
            [112.7912902, -7.0297912],
            [112.7752359, -7.0296739]
          ]
        ]
      }
    }
  ]
}
polygon = geojson_data["features"][0]["geometry"]
```

## 2. Crawling Ulang Data CO

Data CO diunduh ulang dari Copernicus Data Space Ecosystem menggunakan openEO, dengan `spatial_extent` berupa polygon kecamatan Burneh (bukan bounding box kabupaten seperti sebelumnya), periode tetap 24 Agustus 2025 - 24 Agustus 2026.

```python
import openeo
import netCDF4
import numpy as np
import pandas as pd

connection = openeo.connect("openeo.dataspace.copernicus.eu")
connection.authenticate_oidc()

periode = ["2025-08-24", "2026-08-24"]

cube = connection.load_collection(
    "SENTINEL_5P_L2",
    temporal_extent=periode,
    spatial_extent=polygon,
    bands=["CO"],
)
cube_daily = cube.aggregate_temporal_period(reducer="mean", period="day")
cube_daily.execute_batch(title="CO crawl Burneh", outputfile="CO_burneh.nc")
```

```python
def nc_to_daily_raw(nc_path, band):
    ds = netCDF4.Dataset(nc_path)
    raw = ds.variables[band][:]
    time = ds.variables["t"][:]
    dates = netCDF4.num2date(time, units=ds.variables["t"].units)
    filled = raw.astype(np.float64).filled(np.nan)
    daily_dates = [d.strftime("%Y-%m-%d") for d in dates]
    daily_values = [float(np.nanmean(filled[i])) for i in range(filled.shape[0])]
    df = pd.DataFrame({"date": daily_dates, band: daily_values})
    df["date"] = pd.to_datetime(df["date"])
    return df.set_index("date")

df_co = nc_to_daily_raw("CO_burneh.nc", "CO")
df_co.to_csv("co_burneh_raw.csv")
```

Data direindex ke kalender penuh 366 hari (24 Agustus 2025 - 24 Agustus 2026) agar seluruh tanggal tercakup, termasuk yang tidak tercatat sama sekali oleh satelit:

```python
full_range = pd.date_range(start="2025-08-24", end="2026-08-24", freq="D")
df_co = df_co.reindex(full_range)
df_co.index.name = "date"

print(f"Total hari: {len(df_co)}")
print(f"Data asli (tidak kosong): {df_co['CO'].notna().sum()}")
print(f"Data kosong: {df_co['CO'].isna().sum()}")
```

**Hasil identifikasi missing value:** 204 dari 366 hari kosong (55.7%). Persentase ini lebih tinggi dibanding pengamatan sebelumnya pada cakupan kabupaten, karena area kecamatan yang lebih sempit membuat satu kejadian tutupan awan berpotensi menutupi seluruh area pengamatan sekaligus.

## 3. Imputasi Missing Value

Karena proporsi missing value sangat besar (55.7%, jauh di atas 50%), metode interpolasi linier sederhana dipertimbangkan ulang. Interpolasi linier hanya cocok untuk kekosongan pendek (1-3 hari berurutan); pada kekosongan panjang (berminggu-minggu), metode ini menghasilkan segmen data yang datar secara artifisial, menghilangkan karakteristik fluktuasi harian CO yang sebenarnya dipengaruhi pola aktivitas transportasi/industri harian dan mingguan.

Dua metode dijalankan untuk perbandingan:

```python
import matplotlib.pyplot as plt

# Metode 1: Interpolasi Linear (pembanding)
df_co_linear = df_co.copy()
df_co_linear["CO"] = df_co_linear["CO"].interpolate(method="time", limit_direction="both")
df_co_linear.to_csv("co_burneh_imputed_linear.csv")

# Metode 2: Seasonal/Kalender Imputation (FINAL)
df_co_seasonal = df_co.copy()
df_co_seasonal["CO"] = df_co_seasonal["CO"].fillna(
    df_co_seasonal.groupby(df_co_seasonal.index.dayofweek)["CO"].transform("mean")
)
df_co_seasonal["CO"] = df_co_seasonal["CO"].interpolate(method="time", limit_direction="both")
df_co_seasonal.to_csv("co_burneh_imputed_seasonal.csv")

print(f"Linear   - missing tersisa: {df_co_linear['CO'].isna().sum()}")
print(f"Seasonal - missing tersisa: {df_co_seasonal['CO'].isna().sum()}")

fig, axes = plt.subplots(2, 1, figsize=(12, 8), sharex=True)
axes[0].plot(df_co_linear.index, df_co_linear["CO"], linewidth=1, color="gray")
axes[0].set_title("Metode 1: Interpolasi Linear (pembanding)")
axes[0].set_ylabel("CO")
axes[1].plot(df_co_seasonal.index, df_co_seasonal["CO"], linewidth=1, color="steelblue")
axes[1].set_title("Metode 2: Seasonal/Kalender Imputation (FINAL)")
axes[1].set_ylabel("CO")
axes[1].set_xlabel("Tanggal")
plt.tight_layout()
plt.savefig("perbandingan_imputasi_co.png", dpi=150)
plt.show()
```
![burneh](../img/udara/imputasi.png)

**Metode final: Seasonal/Kalender Imputation.** Nilai kosong ditambal menggunakan rata-rata dari hari-dalam-minggu yang sama (misal: Senin yang kosong diisi rata-rata seluruh hari Senin lain yang datanya tersedia), sehingga karakteristik pola mingguan CO (hari kerja vs akhir pekan) tetap terjaga. Perbandingan visual menunjukkan perbedaan yang jelas pada periode dengan kekosongan beruntun panjang (sekitar akhir Oktober - pertengahan November 2025): metode interpolasi linier menghasilkan segmen datar secara artifisial pada periode tersebut, sedangkan metode seasonal tetap mempertahankan variasi harian yang konsisten dengan pola di bagian data lain. Hasil akhir: 0 missing value dari 366 hari.

## 4. Deteksi & Perbaikan Outlier

**Catatan metodologis penting:** deteksi outlier awal yang dilakukan pada seluruh 366 hari (termasuk 204 hari hasil imputasi) menghasilkan 55 titik terdeteksi sebagai outlier. Namun, pendekatan ini keliru: nilai hasil imputasi seasonal bersifat sangat seragam (over-smoothing), sehingga mendominasi perhitungan kuartil dan membuat rentang IQR menjadi sangat sempit. Akibatnya, data asli yang variasinya alami justru salah terdeteksi sebagai outlier, padahal yang menyimpang sebenarnya adalah dominasi data hasil tambalan.

**Metode final (Subset-Based IQR):** deteksi outlier diisolasi hanya pada data asli (162 hari yang benar-benar tercatat satelit), tidak mencampurkan data hasil imputasi ke dalam perhitungan kuartil.

```python
data_asli = df_co[df_co["CO"].notna()]

Q1_asli = data_asli["CO"].quantile(0.25)
Q3_asli = data_asli["CO"].quantile(0.75)
IQR_asli = Q3_asli - Q1_asli
batas_bawah_asli = Q1_asli - 1.5 * IQR_asli
batas_atas_asli = Q3_asli + 1.5 * IQR_asli

outlier_asli_mask = (data_asli["CO"] < batas_bawah_asli) | (data_asli["CO"] > batas_atas_asli)

print(f"Q1={Q1_asli:.4f}, Q3={Q3_asli:.4f}, IQR={IQR_asli:.4f}")
print(f"Batas bawah={batas_bawah_asli:.4f}, Batas atas={batas_atas_asli:.4f}")
print(f"Jumlah outlier sejati: {outlier_asli_mask.sum()} dari {len(data_asli)} data asli")
print(data_asli[outlier_asli_mask])
```

**Hasil:** Q1 = 0.0262, Q3 = 0.0315, IQR = 0.0054, batas bawah = 0.0181, batas atas = 0.0395. Ditemukan **1 outlier sejati**: tanggal 2025-10-07 dengan nilai 0.046827.

Outlier diperbaiki menggunakan **capping (winsorization)** — nilai yang melebihi batas digantikan dengan nilai batas terdekat, kemudian digabungkan kembali dengan data hasil imputasi seasonal menjadi variabel final `df_co_fixed`.

```python
data_asli_clean = data_asli.copy()
data_asli_clean["CO"] = data_asli_clean["CO"].clip(lower=batas_bawah_asli, upper=batas_atas_asli)

df_co_fixed = df_co_seasonal.copy()
df_co_fixed.update(data_asli_clean)

print(f"df_co_fixed - missing: {df_co_fixed['CO'].isna().sum()}, total hari: {len(df_co_fixed)}")
df_co_fixed.to_csv("co_burneh_fixed.csv")
```

**Hasil akhir:** `df_co_fixed` — 366 hari, 0 missing value, 0 outlier ekstrem, siap digunakan sebagai input ekstraksi fitur.

## 5. Ekstraksi Fitur menggunakan TSFEL

Fitur time series diekstrak dari 366 hari data CO yang telah bersih (`df_co_fixed`) menggunakan library TSFEL. ekstraksi dilakukan dengan memanggil setiap dari 68 fungsi fitur TSFEL secara langsung dan merapikan hasilnya menjadi satu nilai skalar per fitur.

```python
import pandas as pd
import numpy as np
import inspect
import tsfel.feature_extraction.features as tsfel_features

target_pollutant = "CO"
df_co_fixed[target_pollutant] = pd.to_numeric(df_co_fixed[target_pollutant], errors="coerce")
signal_1d = df_co_fixed[target_pollutant].astype(float).values
fs = 1

FEATURE_LIST = """abs_energy auc autocorr average_power calc_centroid calc_max calc_mean
calc_median calc_min calc_std calc_var dfa distance ecdf ecdf_percentile ecdf_percentile_count
ecdf_slope entropy fundamental_frequency higuchi_fractal_dimension hist_mode human_range_energy
hurst_exponent interq_range kurtosis lempel_ziv lpcc max_frequency max_power_spectrum
maximum_fractal_length mean_abs_deviation mean_abs_diff mean_diff median_abs_deviation
median_abs_diff median_diff median_frequency mfcc mse negative_turning neighbourhood_peaks
petrosian_fractal_dimension pk_pk_distance positive_turning power_bandwidth rms skewness slope
spectral_centroid spectral_decrease spectral_distance spectral_entropy spectral_kurtosis
spectral_positive_turning spectral_roll_off spectral_roll_on spectral_skewness spectral_slope
spectral_spread spectral_variation spectrogram_mean_coeff sum_abs_diff wavelet_abs_mean
wavelet_energy wavelet_entropy wavelet_std wavelet_var zero_cross""".split()

def to_scalar(result):
    if isinstance(result, dict) and "values" in result:
        result = result["values"]
    if isinstance(result, (list, tuple, np.ndarray)):
        return float(np.nanmean(np.asarray(result, dtype=float)))
    return float(result)

def extract_one(fn_name, signal, fs):
    fn = getattr(tsfel_features, fn_name)
    params = inspect.signature(fn).parameters
    return to_scalar(fn(signal, fs) if "fs" in params else fn(signal))

row = {fn_name: extract_one(fn_name, signal_1d, fs) for fn_name in FEATURE_LIST}
fitur_co_final = pd.DataFrame([row])

print(f"Jumlah fitur yang diekstrak: {fitur_co_final.shape[1]}")
fitur_co_final.to_csv("CO_burneh_TSFEL.csv", index=False)
```
|index|abs\_energy|auc|autocorr|average\_power|calc\_centroid|calc\_max|calc\_mean|calc\_median|calc\_min|calc\_std|calc\_var|dfa|distance|ecdf|ecdf\_percentile|ecdf\_percentile\_count|ecdf\_slope|entropy|fundamental\_frequency|higuchi\_fractal\_dimension|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|0|0\.3057765219540027|10\.51327587688876|1\.0|0\.0008377438957643|181\.14325128787507|0\.0395294411573559|0\.0287929115671036|0\.0291458663895078|0\.0199626348912715|0\.0025344075255071|6\.423221505347478e-06|0\.6626065277451716|365\.0020862679126|0\.0150273224043715|0\.0285519167026948|182\.5|665\.4464873178209|0\.68129178750609|0\.0027322404371584|2\.0055890472360893|

**Hasil:** 68 fitur berhasil diekstrak dalam satu baris (1 nilai per fitur), mencakup domain Statistical, Temporal, dan Spectral. Fitur `ecdf_slope` yang pada percobaan awal perlu dihitung manual, ternyata tersedia sebagai fungsi langsung di modul TSFEL dan dapat dipanggil seperti fitur lainnya.

## 6. Penjelasan Domain dan Fitur TSFEL

TSFEL mengelompokkan fitur deret waktu ke dalam tiga domain utama: **Statistical** (mendeskripsikan sebaran nilai tanpa memperhatikan urutan waktu), **Temporal** (mendeskripsikan pola dan perilaku sinyal sepanjang waktu), dan **Spectral** (mendeskripsikan sinyal setelah ditransformasikan ke ranah frekuensi). Berikut penjelasan setiap fitur yang berhasil diekstrak dari data CO.

### Domain Statistical

Domain ini merangkum karakteristik distribusi nilai CO secara keseluruhan, tanpa mempedulikan kapan nilai itu muncul.

- **calc_min, calc_max**: nilai terendah dan tertinggi yang tercatat pada deret data.
- **calc_mean**: rata-rata seluruh nilai, dihitung dengan menjumlahkan semua data lalu membagi dengan jumlah data.
- **calc_median**: nilai tengah setelah data diurutkan.
- **calc_std, calc_var**: standar deviasi dan variansnya, mengukur seberapa lebar sebaran nilai di sekitar rata-rata.
- **skewness**: mengukur kemiringan distribusi (condong ke kiri atau kanan terhadap rata-rata).
- **kurtosis**: mengukur ketajaman puncak dan ketebalan ekor distribusi, menandakan seberapa sering muncul nilai ekstrem.
- **interq_range**: rentang interkuartil (Q3 dikurangi Q1), ukuran sebaran yang tidak terlalu terpengaruh outlier.
- **mean_abs_deviation**: rata-rata dari selisih absolut tiap nilai terhadap rata-rata keseluruhan.
- **median_abs_deviation**: sama seperti di atas, tetapi dihitung terhadap median, sehingga lebih tahan terhadap outlier.
- **rms (root mean square)**: akar dari rata-rata kuadrat seluruh nilai, mencerminkan besaran energi rata-rata sinyal.
- **hist_mode**: nilai yang paling sering muncul (modus) ketika data dikelompokkan ke dalam histogram.
- **ecdf**: nilai fungsi distribusi kumulatif empiris (Empirical Cumulative Distribution Function), menggambarkan proporsi data yang berada di bawah suatu nilai tertentu.
- **ecdf_percentile**: nilai ECDF pada persentil tertentu (mis. 25% dan 75%).
- **ecdf_percentile_count**: jumlah titik data yang berada di bawah suatu persentil ECDF tertentu.
- **ecdf_slope**: kemiringan garis ECDF antara dua titik persentil, mencerminkan seberapa cepat distribusi data naik pada rentang tersebut.

### Domain Temporal

Domain ini menilai bagaimana nilai CO berubah dan berpola sepanjang waktu, termasuk tren, kompleksitas, dan tingkat keteraturan sinyal.

- **abs_energy**: total energi sinyal, dihitung dari jumlah kuadrat seluruh nilai.
- **auc (area under curve)**: luas area di bawah kurva deret waktu.
- **average_power**: rata-rata daya sinyal terhadap waktu (energi dibagi durasi).
- **autocorr**: autokorelasi, mengukur seberapa mirip sinyal dengan versi tergesernya sendiri (misal, apakah nilai hari ini berkorelasi dengan nilai kemarin).
- **calc_centroid**: titik pusat massa sinyal di sepanjang sumbu waktu.
- **distance**: total panjang lintasan yang ditempuh sinyal dari titik pertama ke titik terakhir.
- **entropy**: mengukur tingkat ketidakteraturan atau ketidakpastian pola dalam sinyal; makin acak, makin tinggi entropinya.
- **slope**: kemiringan garis tren linear yang paling mendekati keseluruhan data (naik atau turun secara umum).
- **mean_diff, median_diff**: rata-rata dan median dari selisih antar nilai berurutan (menunjukkan laju perubahan harian).
- **mean_abs_diff, median_abs_diff**: sama seperti di atas, tetapi menggunakan nilai absolut sehingga arah naik/turun tidak saling meniadakan.
- **sum_abs_diff**: total akumulasi dari seluruh selisih absolut antar hari.
- **mse (mean squared error)**: rata-rata kuadrat selisih antara sinyal dan model referensinya.
- **negative_turning, positive_turning**: jumlah titik balik di mana tren berubah dari naik ke turun, atau dari turun ke naik.
- **neighbourhood_peaks**: jumlah titik puncak lokal yang terdeteksi dalam suatu jendela pengamatan.
- **pk_pk_distance (peak-to-peak distance)**: selisih antara nilai puncak tertinggi dan lembah terendah.
- **zero_cross**: jumlah kali sinyal melewati garis nol (atau nilai tengah tertentu).
- **dfa (detrended fluctuation analysis)**: mengukur ketergantungan jangka panjang dalam data setelah tren dihilangkan.
- **hurst_exponent**: menunjukkan apakah pola naik-turun cenderung berlanjut (memori jangka panjang) atau acak.
- **higuchi_fractal_dimension, petrosian_fractal_dimension** — dua cara berbeda mengukur seberapa kompleks/bergeriginya bentuk sinyal secara matematis.
- **maximum_fractal_length**: panjang maksimum lintasan fraktal yang teramati pada berbagai skala waktu.
- **lempel_ziv**: mengukur kompleksitas sinyal berdasarkan seberapa banyak pola berulang yang bisa "dikompresi".

### Domain Spectral

Domain ini mengubah sinyal CO ke ranah frekuensi (menggunakan transformasi Fourier atau wavelet) untuk melihat pola periodik yang tidak terlihat langsung dari data mentah.

- **fundamental_frequency**: frekuensi dominan/paling menonjol dalam sinyal, menandakan siklus utama yang berulang.
- **max_frequency, median_frequency**: frekuensi tertinggi dan frekuensi tengah (median) dari distribusi daya spektrum.
- **max_power_spectrum**: nilai daya (energi) tertinggi yang ditemukan pada frekuensi dominan.
- **power_bandwidth**: lebar pita frekuensi tempat sebagian besar energi sinyal terkonsentrasi.
- **human_range_energy**: proporsi energi sinyal yang berada pada rentang frekuensi tertentu yang relevan.
- **spectral_centroid**: titik berat frekuensi; menunjukkan apakah energi lebih terkonsentrasi di frekuensi rendah atau tinggi.
- **spectral_spread**: seberapa lebar sebaran energi di sekitar spectral centroid.
- **spectral_skewness, spectral_kurtosis**: versi domain frekuensi dari skewness dan kurtosis, mengukur bentuk kurva distribusi daya spektrum.
- **spectral_decrease, spectral_slope**: mengukur seberapa cepat daya spektrum menurun seiring naiknya frekuensi.
- **spectral_distance**: ukuran perbedaan antara profil spektrum sinyal dan bentuk referensinya.
- **spectral_entropy**: entropi pada ranah frekuensi, mengukur seberapa merata energi tersebar di berbagai frekuensi (semakin merata, semakin tinggi).
- **spectral_positive_turning**: jumlah titik balik naik pada kurva kepadatan spektral.
- **spectral_roll_off, spectral_roll_on**: titik frekuensi tempat sebagian besar (misalnya 95%) energi sinyal sudah terakumulasi, dilihat dari sisi atas maupun bawah spektrum.
- **spectral_variation**: seberapa besar variasi/perubahan bentuk spektrum dari waktu ke waktu.
- **spectrogram_mean_coeff**: rata-rata nilai koefisien dari representasi spektrogram (peta waktu-frekuensi) sinyal.
- **lpcc (linear prediction cepstral coefficients)**: koefisien yang merepresentasikan bentuk spektral sinyal secara ringkas, umum dipakai untuk mengenali pola/tekstur frekuensi.
- **mfcc (mel-frequency cepstral coefficients)**: mirip lpcc, representasi ringkas spektrum yang mengikuti skala frekuensi mel, sering dipakai dalam pengenalan pola sinyal.
- **wavelet_abs_mean, wavelet_std, wavelet_var**: rata-rata mutlak, standar deviasi, dan varians dari koefisien hasil transformasi wavelet, yang memecah sinyal ke berbagai skala waktu-frekuensi sekaligus.
- **wavelet_energy**: total energi yang terkandung dalam koefisien wavelet.
- **wavelet_entropy**: tingkat ketidakteraturan yang terukur dari distribusi energi antar skala wavelet.

## Ringkasan Alur

```
Crawling CO (polygon Kecamatan Burneh, 24 Agst 2025 - 24 Agst 2026)
    -> df_co (366 hari, 204 kosong / 55.7%, 162 data asli)
    -> Deteksi outlier subset-based di 162 data asli -> 1 outlier sejati (2025-10-07)
    -> Imputasi: Linear (pembanding) vs Seasonal (FINAL) -> df_co_seasonal (0 kosong)
    -> Capping outlier (dari df_co asli) + gabung ke df_co_seasonal -> df_co_fixed (366 hari, 0 kosong, 0 outlier)
    -> Ekstraksi TSFEL: panggil 68 fungsi fitur langsung dari tsfel.feature_extraction.features -> 68 fitur (68 kolom)
    -> CO_burneh_TSFEL.csv
```

# Tugas 4 — K-Means Clustering (KNIME)

Dokumentasi ini menyajikan analisis pengelompokan (*clustering*) data deret waktu 4 polutan udara (CO, NO2, SO2, CH4) dari 19 mahasiswa/wilayah pengamatan menggunakan **KNIME Analytics Platform** dengan algoritma **K-Means**.

Tujuan analisis ini adalah membandingkan dua pendekatan pengolahan:

1. **Dengan PCA (19 Dimensi)**: mereduksi 272 fitur awal menjadi 19 komponen utama sebelum dikelompokkan K-Means.
2. **Tanpa PCA (272 Fitur Penuh)**: memasukkan seluruh 272 fitur numerik TSFEL langsung ke K-Means tanpa reduksi dimensi.

Masing-masing pendekatan diuji dengan jumlah klaster k=3 dan k=5.

## 1. Karakteristik Data Input

Dataset merupakan gabungan fitur hasil ekstraksi TSFEL dari 19 mahasiswa/wilayah observasi. Setiap mahasiswa direpresentasikan oleh 272 fitur numerik:

```
Total Fitur = 4 Polutan x 68 Fitur TSFEL = 272 Fitur
```

Keempat polutan yang dianalisis: **CO** (Karbon Monoksida), **NO2** (Nitrogen Dioksida), **SO2** (Sulfur Dioksida), **CH4** (Metana) — masing-masing menyumbang 68 fitur statistical, temporal, dan spectral.

## 2. Alur Kerja (Workflow) di KNIME

![node-knime](../img/tugas4/node_knime.png)

```
Excel Reader
    -> Column Filter (buang Nama, Daerah)
    -> Normalizer (Z-Score)
    -> [Jalur A: PCA (19 dimensi) -> k-Means]
    -> [Jalur B: k-Means langsung, tanpa PCA]

Tiap k-Means bercabang dua:
    k-Means -> Silhouette Coefficient -> Table View
    k-Means -> Joiner (+ Excel Reader) -> Python Script -> Scatter Plot
```

### Penjelasan Node

1. **Excel Reader** — membaca berkas kompilasi data 19 mahasiswa (kolom `Nama`, `Daerah`, dan 272 kolom fitur).
2. **Column Filter** — memisahkan kolom identitas (`Nama`, `Daerah`) dari kolom fitur numerik, karena PCA/K-Means hanya menerima data numerik.
3. **Normalizer (Z-Score)** — menstandarkan skala seluruh fitur, agar fitur berskala besar (mis. CH4) tidak mendominasi fitur berskala kecil (mis. NO2) dalam perhitungan jarak.
4. **PCA** — mereduksi 272 fitur menjadi 19 komponen utama (jumlah dimensi = jumlah mahasiswa).
5. **k-Means** — mengelompokkan data ke dalam *k* klaster, dijalankan 4 kali (k=3/k=5, dengan/tanpa PCA).
6. **Silhouette Coefficient** — mengukur seberapa baik tiap data dikelompokkan ke klasternya; nilai mendekati 1 menunjukkan klastering yang baik.
7. **Joiner** — menggabungkan kembali kolom `Nama` (dari Excel Reader) ke hasil k-Means (yang sudah kehilangan kolom `Nama` setelah PCA/K-Means), berdasarkan RowID.
8. **Python Script** — mengekspor hasil cluster assignment ke CSV untuk divisualisasikan.
9. **Scatter Plot** (dibuat dari CSV hasil ekspor, lihat kode Python di bagian akhir) — memvisualisasikan sebaran mahasiswa per klaster.

## 3. Hasil per Skenario

### 3.1 Klastering k=3, Tanpa PCA

*Tabel Silhouette Coefficient:*

![k3-nopca](../img/tugas4/k3_nopca_knime.png)

| Klaster | Mean Silhouette |
|---|---|
| cluster_0 | -0.138 |
| cluster_1 | 0 |
| cluster_2 | 0 |
| **Overall** | **-0.123** |

*Scatter Plot:*

![k3-nopca](../img/tugas4/k3_nopca.png)

**Ringkasan:** `cluster_0` menampung 17 mahasiswa, sedangkan `cluster_1` (Raihan Aryanova Narendra) dan `cluster_2` (Wildan Haydar Amru) masing-masing hanya berisi 1 anggota (silhouette = 0). 

### 3.2 Klastering k=5, Tanpa PCA

*Tabel Silhouette Coefficient:*

![k5-nopca](../img/tugas4/k5_nopca_knime.png)

| Klaster | Mean Silhouette |
|---|---|
| cluster_0 | -0.079 |
| cluster_1 | 0.408 |
| cluster_2 | 0 |
| cluster_3 | 0 |
| cluster_4 | 0 |
| **Overall** | **0.010** |

*Scatter Plot:*

![k5-nopca](../img/tugas4/k3_nopca.png)

**Ringkasan:** `cluster_0` berisi 13 mahasiswa, `cluster_1` berisi 3 mahasiswa (Kevin Koligombowo Mangaraja, Mohammad Waqidi, fikri mutawakkil), dan `cluster_2`, `cluster_3`, `cluster_4` masing-masing 1 anggota (Muhammad Fathul Iman Wahid, Raihan Aryanova Narendra, Wildan Haydar Amru).

### 3.3 Klastering k=3, Dengan PCA

*Tabel Silhouette Coefficient:*

![k3-pca](../img/tugas4/k3_pca_knime.png)


| Klaster | Mean Silhouette |
|---|---|
| cluster_0 | -0.138 |
| cluster_1 | 0 |
| cluster_2 | 0 |
| **Overall** | **-0.123** |

*Scatter Plot:*

![k3-pca](../img/tugas4/k3_pca.png)

**Ringkasan:** `cluster_0` menampung 17 mahasiswa, sedangkan `cluster_1` (Raihan Aryanova Narendra) dan `cluster_2` (Wildan Haydar Amru) masing-masing hanya berisi 1 anggota (silhouette = 0). Hasilnya identik dengan skenario 3.1.

### 3.4 Klastering k=5, Dengan PCA

*Tabel Silhouette Coefficient:*

![k5-pca](../img/tugas4/k5_pca_knime.png)


| Klaster | Mean Silhouette |
|---|---|
| cluster_0 | -0.079 |
| cluster_1 | 0.408 |
| cluster_2 | 0 |
| cluster_3 | 0 |
| cluster_4 | 0 |
| **Overall** | **0.010** |

*Scatter Plot:*
![k5-pca](../img/tugas4/k5_pca.png)

**Ringkasan:** `cluster_0` berisi 13 mahasiswa, `cluster_1` berisi 3 mahasiswa (Kevin Koligombowo Mangaraja, Mohammad Waqidi, fikri mutawakkil), dan `cluster_2`, `cluster_3`, `cluster_4` masing-masing 1 anggota (Muhammad Fathul Iman Wahid, Raihan Aryanova Narendra, Wildan Haydar Amru). Hasilnya identik dengan skenario 3.2.

## 4. Kode Ekspor CSV (Python Script Legacy, di KNIME)

Dipasang setelah node **Joiner** pada tiap skenario:

```python
import os

data = input_table_1
data.to_csv("hasil_k3_nopca.csv", index=False)  # ganti nama sesuai skenario
print("Disimpan di:", os.path.abspath("hasil_k3_nopca.csv"))
output_table_1 = data
```

Nama file per skenario: `hasil_k3_nopca.csv`, `hasil_k5_nopca.csv`, `hasil_k3_pca.csv`, `hasil_k5_pca.csv`.

## 5. Kode Scatter Plot (Google Colab)

```python
import pandas as pd
import matplotlib.pyplot as plt

skenario = [
    ("hasil_k3_nopca.csv", "k=3, Tanpa PCA", "img_k3_nopca/scatter_k3_nopca.png"),
    ("hasil_k5_nopca.csv", "k=5, Tanpa PCA", "img_k5_nopca/scatter_k5_nopca.png"),
    ("hasil_k3_pca.csv", "k=3, Dengan PCA", "img_k3_pca/scatter_k3_pca.png"),
    ("hasil_k5_pca.csv", "k=5, Dengan PCA", "img_k5_pca/scatter_k5_pca.png"),
]

for fname, judul, output_path in skenario:
    data = pd.read_csv(fname)
    K = data["Cluster"].nunique()
    x = range(len(data))
    y = data["Cluster"]

    plt.figure(figsize=(14, 5))
    plt.scatter(x, y, s=25, color="#6b8bd6")
    plt.xticks(x, data["Nama"], rotation=90, fontsize=7)
    plt.yticks(range(K), [f"cluster_{i}" for i in range(K)])
    plt.ylim(-0.5, K - 0.5)
    plt.title(f"Scatter Plot - {judul}", loc="left", fontweight="bold")
    plt.xlabel("Nama")
    plt.ylabel("Cluster")
    plt.grid(True, color="#eeeeee")
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.show()
```

## 7. Kesimpulan

### Perbandingan Silhouette Coefficient (Overall)

| Skenario | Tanpa PCA (272 fitur) | Dengan PCA (19 komponen) |
|---|---|---|
| k=3 | -0.123 | -0.123 |
| k=5 | 0.010 | 0.010 |

1. **k=5 menghasilkan Silhouette tertinggi** (0.010 vs -0.123 untuk k=3). Namun nilai 0.010 masih sangat dekat dengan 0, artinya struktur klaster pada data ini lemah dan tidak terpisah dengan jelas. Satu-satunya klaster yang cukup padat adalah `cluster_1` pada k=5 (0.408, 3 anggota).
2. **Hasil PCA dan tanpa PCA identik**, baik nilai Silhouette maupun anggota kelompoknya. Penyebabnya: data hanya 19 baris, sehingga setelah dinormalisasi (dipusatkan) rank data paling banyak 18. PCA dengan 19 komponen berarti hanya memutar sumbu tanpa membuang variansi, sehingga jarak antar data tidak berubah dan K-Means menghasilkan klaster yang sama. Reduksi dimensi baru berpengaruh jika jumlah komponen dibuat lebih kecil dari jumlah data (mis. komponen yang menjelaskan 90-95% variansi).
3. **Klaster sangat tidak seimbang**: pada k=3, 17 dari 19 mahasiswa berada di `cluster_0` (silhouette -0.138), sedangkan sisanya terpisah sebagai klaster beranggota tunggal. Raihan Aryanova Narendra dan Wildan Haydar Amru selalu terpisah sendiri di semua skenario, sehingga keduanya kemungkinan *outlier* pada 272 fitur. Silhouette klaster beranggota tunggal didefinisikan 0, sehingga nilai *overall* ditentukan hampir sepenuhnya oleh klaster besar yang bernilai negatif (k=3) atau mendekati nol (k=5).
4. **Kemungkinan penyebab lain**: jumlah fitur (272) jauh lebih besar dari jumlah data (19), sehingga jarak Euclidean menjadi kurang membedakan (*curse of dimensionality*). Data yang digunakan juga belum tentu memiliki kelompok alami.