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

---
# Tugas 5 - Preprocessing untuk Outlier dan Polinomial

## Preprocessing: Penanganan Outliers dan Interpolasi Polinomial

Sebelum dilakukan analisis lebih lanjut, data polutan Burneh periode 24 Agustus 2025 – 23 Agustus 2026 perlu melalui tahap preprocessing. Data hasil crawling memiliki dua masalah utama: banyak nilai kosong (missing value) dan adanya outlier. Outlier perlu ditangani karena nilai yang menyimpang jauh dapat memengaruhi hasil analisis, salah satunya pada proses clustering.

Deteksi outlier dilakukan menggunakan metode **Interquartile Range (IQR)**. Data diurutkan, lalu dihitung kuartil pertama (Q1) dan kuartil ketiga (Q3). Nilai yang berada di luar batas bawah dan batas atas dianggap sebagai outlier:

```text
IQR = Q3 - Q1

Batas bawah = Q1 - 1.5 × IQR
Batas atas  = Q3 + 1.5 × IQR
```

Nilai yang terdeteksi sebagai outlier kemudian diubah menjadi `NaN` (diperlakukan sebagai missing value) dan diisi menggunakan **interpolasi polinomial orde 1** (`method='polynomial', order=1`), yaitu memperkirakan nilai kosong berdasarkan nilai di sekitarnya. Pada bagian tepi data yang tidak dapat diinterpolasi, digunakan `bfill()` (mengisi dari nilai sesudahnya) dan `ffill()` (mengisi dari nilai sebelumnya).

Karena nilai hasil interpolasi dapat mengubah distribusi data, proses deteksi outlier diulang secara **iteratif** (menggunakan loop) sampai tidak ditemukan outlier lagi.

### 1. Karbon Monoksida (CO)

Data CO terlebih dahulu diperiksa untuk mengetahui adanya nilai yang termasuk outlier. Deteksi outlier dilakukan menggunakan metode IQR. Dari 365 hari data, terdapat 160 data asli dan 205 data kosong. Setelah dihitung, ditemukan 1 outlier pada data CO.

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# 1. Load data raw CO dari hasil crawler
df = pd.read_csv("co_burneh_raw.csv")
df['date'] = pd.to_datetime(df['date'])
df = df.sort_values('date').reset_index(drop=True)
df['CO'] = pd.to_numeric(df['CO'], errors='coerce')

# 2. Hitung IQR
Q1 = df['CO'].quantile(0.25)
Q3 = df['CO'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# 3. Filter outlier
outliers_iqr = df[(df['CO'] &lt; lower_bound) | (df['CO'] &gt; upper_bound)]
print("Jumlah Outlier CO (IQR):", len(outliers_iqr))
```

Output:

```text
Jumlah Outlier CO (IQR): 1
```

Berikut visualisasi posisi outlier pada data CO:

![outlier co](../img/tugas5/prepo/outlierdataco.png)
```python
plt.figure(figsize=(15, 5))
plt.plot(df['date'], df['CO'], label="CO", linewidth=1)
plt.scatter(outliers_iqr['date'], outliers_iqr['CO'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Deteksi Outlier Data CO (Metode IQR)")
plt.xlabel("Tanggal")
plt.ylabel("Kadar CO")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df['date'].iloc[0], df['date'].iloc[-1]],
           labels=[df['date'].iloc[0].date(), df['date'].iloc[-1].date()])
plt.show()
```

Outlier dan data kosong kemudian dibersihkan dengan interpolasi polinomial secara iteratif sampai tidak ada outlier tersisa:

```python
df['CO_filled'] = df['CO'].copy()

# Looping iteratif untuk membersihkan outlier sampai benar-benar habis
while True:
    # 1. Hitung ulang kuartil dan batas IQR berdasarkan data saat ini
    Q1 = df['CO_filled'].quantile(0.25)
    Q3 = df['CO_filled'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    # 2. Deteksi lokasi outlier
    outliers = (df['CO_filled'] &lt; lower_bound) | (df['CO_filled'] &gt; upper_bound)

    # Jika sudah tidak ada outlier yang terdeteksi, hentikan perulangan
    if not outliers.any():
        break

    # 3. Mask nilai outlier menjadi NaN, lalu isi dengan interpolasi polinomial + bfill + ffill
    df['CO_filled'] = df['CO_filled'].mask(outliers)
    df['CO_filled'] = df['CO_filled'].interpolate(method='polynomial', order=1).bfill().ffill()

# 4. Simpan hasil akhir ke DataFrame baru dan ekspor ke CSV
df_co = pd.DataFrame({"date": df['date'], "CO": df['CO_filled']})
df_co.to_csv("co_burneh_clean.csv", index=False)
print("Data CO berhasil diproses dan disimpan ke co_burneh_clean.csv")
```

Output:

```text
Data CO berhasil diproses dan disimpan ke co_burneh_clean.csv
```

Hasil akhir divisualisasikan untuk memastikan data sudah bersih dari outlier:

![intepolasi co](../img/tugas5/prepo/interpolasidataco.png)

```python
df_co_final = pd.read_csv("co_burneh_clean.csv")
df_co_final['date'] = pd.to_datetime(df_co_final['date'])

Q1 = df_co_final['CO'].quantile(0.25)
Q3 = df_co_final['CO'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers_iqr = df_co_final[(df_co_final['CO'] &lt; lower_bound) | (df_co_final['CO'] &gt; upper_bound)]

plt.figure(figsize=(15, 5))
plt.plot(df_co_final['date'], df_co_final['CO'], label="CO", linewidth=1, color='green')
plt.scatter(outliers_iqr['date'], outliers_iqr['CO'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Visualisasi Data CO Setelah Interpolasi")
plt.xlabel("Tanggal")
plt.ylabel("Kadar CO")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_co_final['date'].iloc[0], df_co_final['date'].iloc[-1]],
           labels=[df_co_final['date'].iloc[0].date(), df_co_final['date'].iloc[-1].date()])
plt.show()
```

### 2. Nitrogen Dioksida (NO₂)

Proses yang sama dilakukan pada data NO₂. Dari 365 hari, terdapat 124 data asli dan 241 data kosong. Hasil deteksi IQR menunjukkan 1 outlier pada data NO₂.

```python
# 1. Load data raw NO2
df_no2 = pd.read_csv("no2_burneh_raw.csv")
df_no2['date'] = pd.to_datetime(df_no2['date'])
df_no2 = df_no2.sort_values('date').reset_index(drop=True)
df_no2['NO2'] = pd.to_numeric(df_no2['NO2'], errors='coerce')

# 2. Hitung IQR
Q1 = df_no2['NO2'].quantile(0.25)
Q3 = df_no2['NO2'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# 3. Filter outlier
outliers_iqr = df_no2[(df_no2['NO2'] &lt; lower_bound) | (df_no2['NO2'] &gt; upper_bound)]
print("Jumlah Outlier NO2 (IQR):", len(outliers_iqr))
```

Output:

```text
Jumlah Outlier NO2 (IQR): 1
```
![outlier no](../img/tugas5/prepo/outlierdatano2.png)
```python
plt.figure(figsize=(15, 5))
plt.plot(df_no2['date'], df_no2['NO2'], label="NO2", linewidth=1)
plt.scatter(outliers_iqr['date'], outliers_iqr['NO2'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Deteksi Outlier Data NO2 (Metode IQR)")
plt.xlabel("Tanggal")
plt.ylabel("Kadar NO2")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_no2['date'].iloc[0], df_no2['date'].iloc[-1]],
           labels=[df_no2['date'].iloc[0].date(), df_no2['date'].iloc[-1].date()])
plt.show()
```

Pembersihan outlier dan pengisian data kosong dilakukan dengan interpolasi polinomial orde 1 secara iteratif:

```python
df_no2['NO2_filled'] = df_no2['NO2'].copy()

# Looping iteratif untuk membersihkan outlier sampai benar-benar habis
while True:
    Q1 = df_no2['NO2_filled'].quantile(0.25)
    Q3 = df_no2['NO2_filled'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    outliers = (df_no2['NO2_filled'] &lt; lower_bound) | (df_no2['NO2_filled'] &gt; upper_bound)
    if not outliers.any():
        break

    df_no2['NO2_filled'] = df_no2['NO2_filled'].mask(outliers)
    df_no2['NO2_filled'] = df_no2['NO2_filled'].interpolate(method='polynomial', order=1).bfill().ffill()

# Simpan hasil akhir ke DataFrame baru dan ekspor ke CSV
df_no2_clean = pd.DataFrame({"date": df_no2['date'], "NO2": df_no2['NO2_filled']})
df_no2_clean.to_csv("no2_burneh_clean.csv", index=False)
print("Data NO2 berhasil diproses dan disimpan ke no2_burneh_clean.csv")
```

Output:

```text
Data NO2 berhasil diproses dan disimpan ke no2_burneh_clean.csv
```
![interpolasi no2](../img/tugas5/prepo/interpolasidatano2.png)

```python
df_no2_final = pd.read_csv("no2_burneh_clean.csv")
df_no2_final['date'] = pd.to_datetime(df_no2_final['date'])

Q1 = df_no2_final['NO2'].quantile(0.25)
Q3 = df_no2_final['NO2'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers_iqr = df_no2_final[(df_no2_final['NO2'] &lt; lower_bound) | (df_no2_final['NO2'] &gt; upper_bound)]

plt.figure(figsize=(15, 5))
plt.plot(df_no2_final['date'], df_no2_final['NO2'], label="NO2", linewidth=1, color='green')
plt.scatter(outliers_iqr['date'], outliers_iqr['NO2'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Visualisasi Data NO2 Setelah Interpolasi")
plt.xlabel("Tanggal")
plt.ylabel("Kadar NO2")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_no2_final['date'].iloc[0], df_no2_final['date'].iloc[-1]],
           labels=[df_no2_final['date'].iloc[0].date(), df_no2_final['date'].iloc[-1].date()])
plt.show()
```

### 3. Sulfur Dioksida (SO₂)

Pada data SO₂ terdapat 170 data asli dan 195 data kosong dari total 365 hari. Deteksi IQR menemukan 9 outlier, lebih banyak dibanding polutan lainnya.

```python
# 1. Load data raw SO2
df_so2 = pd.read_csv("so2_burneh_raw.csv")
df_so2['date'] = pd.to_datetime(df_so2['date'])
df_so2 = df_so2.sort_values('date').reset_index(drop=True)
df_so2['SO2'] = pd.to_numeric(df_so2['SO2'], errors='coerce')

# 2. Hitung IQR
Q1 = df_so2['SO2'].quantile(0.25)
Q3 = df_so2['SO2'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# 3. Filter outlier
outliers_iqr = df_so2[(df_so2['SO2'] &lt; lower_bound) | (df_so2['SO2'] &gt; upper_bound)]
print("Jumlah Outlier SO2 (IQR):", len(outliers_iqr))
```

Output:

```text
Jumlah Outlier SO2 (IQR): 9
```
![outlier so2](../img/tugas5/prepo/outlierdataso2.png)
```python
plt.figure(figsize=(15, 5))
plt.plot(df_so2['date'], df_so2['SO2'], label="SO2", linewidth=1)
plt.scatter(outliers_iqr['date'], outliers_iqr['SO2'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Deteksi Outlier Data SO2 (Metode IQR)")
plt.xlabel("Tanggal")
plt.ylabel("Kadar SO2")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_so2['date'].iloc[0], df_so2['date'].iloc[-1]],
           labels=[df_so2['date'].iloc[0].date(), df_so2['date'].iloc[-1].date()])
plt.show()
```

Karena jumlah outliernya lebih banyak, proses iteratif interpolasi akan bekerja lebih lama sampai semua outlier benar-benar habis:

```python
df_so2['SO2_filled'] = df_so2['SO2'].copy()

# Looping iteratif untuk outlier sampai habis
while True:
    Q1 = df_so2['SO2_filled'].quantile(0.25)
    Q3 = df_so2['SO2_filled'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    outliers = (df_so2['SO2_filled'] &lt; lower_bound) | (df_so2['SO2_filled'] &gt; upper_bound)
    if not outliers.any():
        break

    df_so2['SO2_filled'] = df_so2['SO2_filled'].mask(outliers)
    df_so2['SO2_filled'] = df_so2['SO2_filled'].interpolate(method='polynomial', order=1).bfill().ffill()

# Simpan hasil akhir ke DataFrame baru dan ekspor ke CSV
df_so2_clean = pd.DataFrame({"date": df_so2['date'], "SO2": df_so2['SO2_filled']})
df_so2_clean.to_csv("so2_burneh_clean.csv", index=False)
print("Data SO2 berhasil diproses dan disimpan ke so2_burneh_clean.csv")
```

Output:

```text
Data SO2 berhasil diproses dan disimpan ke so2_burneh_clean.csv
```
![interpolasi so2](../img/tugas5/prepo/interpolasidataso2.png)

```python
df_so2_final = pd.read_csv("so2_burneh_clean.csv")
df_so2_final['date'] = pd.to_datetime(df_so2_final['date'])

Q1 = df_so2_final['SO2'].quantile(0.25)
Q3 = df_so2_final['SO2'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers_iqr = df_so2_final[(df_so2_final['SO2'] &lt; lower_bound) | (df_so2_final['SO2'] &gt; upper_bound)]

plt.figure(figsize=(15, 5))
plt.plot(df_so2_final['date'], df_so2_final['SO2'], label="SO2", linewidth=1, color='green')
plt.scatter(outliers_iqr['date'], outliers_iqr['SO2'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Visualisasi Data SO2 Setelah Interpolasi")
plt.xlabel("Tanggal")
plt.ylabel("Kadar SO2")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_so2_final['date'].iloc[0], df_so2_final['date'].iloc[-1]],
           labels=[df_so2_final['date'].iloc[0].date(), df_so2_final['date'].iloc[-1].date()])
plt.show()
```

### 4. Metana (CH₄)

Data CH₄ memiliki kondisi yang berbeda: dari 365 hari hanya terdapat 9 data asli dan 356 data kosong, dengan 2 outlier terdeteksi. Karena jumlah data aslinya sangat sedikit, sebagian besar nilai pada hasil akhir merupakan hasil interpolasi, sehingga interpretasi terhadap data CH₄ perlu dilakukan secara hati-hati.

```python
# 1. Load data raw CH4
df_ch4 = pd.read_csv("ch4_burneh_raw.csv")
df_ch4['date'] = pd.to_datetime(df_ch4['date'])
df_ch4 = df_ch4.sort_values('date').reset_index(drop=True)
df_ch4['CH4'] = pd.to_numeric(df_ch4['CH4'], errors='coerce')

# 2. Hitung IQR
Q1 = df_ch4['CH4'].quantile(0.25)
Q3 = df_ch4['CH4'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# 3. Filter outlier
outliers_iqr = df_ch4[(df_ch4['CH4'] &lt; lower_bound) | (df_ch4['CH4'] &gt; upper_bound)]
print("Jumlah Outlier CH4 (IQR):", len(outliers_iqr))
```

Output:

```text
Jumlah Outlier CH4 (IQR): 2
```
![outlier ch4](../img/tugas5/prepo/outlierdatach4.png)
```python
plt.figure(figsize=(15, 5))
plt.plot(df_ch4['date'], df_ch4['CH4'], label="CH4", linewidth=1)
plt.scatter(outliers_iqr['date'], outliers_iqr['CH4'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Deteksi Outlier Data CH4 (Metode IQR)")
plt.xlabel("Tanggal")
plt.ylabel("Kadar CH4")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_ch4['date'].iloc[0], df_ch4['date'].iloc[-1]],
           labels=[df_ch4['date'].iloc[0].date(), df_ch4['date'].iloc[-1].date()])
plt.show()
```

Proses pembersihan tetap menggunakan interpolasi polinomial orde 1 secara iteratif seperti polutan lainnya:

```python
df_ch4['CH4_filled'] = df_ch4['CH4'].copy()

# Looping iteratif untuk membersihkan outlier sampai benar-benar habis
while True:
    Q1 = df_ch4['CH4_filled'].quantile(0.25)
    Q3 = df_ch4['CH4_filled'].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR

    outliers = (df_ch4['CH4_filled'] &lt; lower_bound) | (df_ch4['CH4_filled'] &gt; upper_bound)
    if not outliers.any():
        break

    df_ch4['CH4_filled'] = df_ch4['CH4_filled'].mask(outliers)
    df_ch4['CH4_filled'] = df_ch4['CH4_filled'].interpolate(method='polynomial', order=1).bfill().ffill()

# Simpan hasil akhir ke DataFrame baru dan ekspor ke CSV
df_ch4_clean = pd.DataFrame({"date": df_ch4['date'], "CH4": df_ch4['CH4_filled']})
df_ch4_clean.to_csv("ch4_burneh_clean.csv", index=False)
print("Data CH4 berhasil diproses dan disimpan ke ch4_burneh_clean.csv")
```

Output:

```text
Data CH4 berhasil diproses dan disimpan ke ch4_burneh_clean.csv
```
![interpolasi co](../img/tugas5/prepo/interpolasidatach4.png)

```python
df_ch4_final = pd.read_csv("ch4_burneh_clean.csv")
df_ch4_final['date'] = pd.to_datetime(df_ch4_final['date'])

Q1 = df_ch4_final['CH4'].quantile(0.25)
Q3 = df_ch4_final['CH4'].quantile(0.75)
IQR = Q3 - Q1
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers_iqr = df_ch4_final[(df_ch4_final['CH4'] &lt; lower_bound) | (df_ch4_final['CH4'] &gt; upper_bound)]

plt.figure(figsize=(15, 5))
plt.plot(df_ch4_final['date'], df_ch4_final['CH4'], label="CH4", linewidth=1, color='green')
plt.scatter(outliers_iqr['date'], outliers_iqr['CH4'],
            color="red", marker='o', label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound (IQR)")
plt.axhline(lower_bound, color='blue', linestyle='dashed', label="Lower Bound (IQR)")
plt.title("Visualisasi Data CH4 Setelah Interpolasi")
plt.xlabel("Tanggal")
plt.ylabel("Kadar CH4")
plt.legend()
plt.tight_layout()
plt.xticks(ticks=[df_ch4_final['date'].iloc[0], df_ch4_final['date'].iloc[-1]],
           labels=[df_ch4_final['date'].iloc[0].date(), df_ch4_final['date'].iloc[-1].date()])
plt.show()
```

### 5. Penggabungan Data Polutan

Setelah keempat polutan selesai diproses, data yang sudah bersih digabungkan berdasarkan kolom `date` menjadi satu dataset gabungan dengan struktur `date | CO | NO2 | SO2 | CH4`, sehingga dapat digunakan sebagai input untuk analisis berikutnya (K-Means Clustering).

```python
df_co  = pd.read_csv("co_burneh_clean.csv")
df_no2 = pd.read_csv("no2_burneh_clean.csv")
df_so2 = pd.read_csv("so2_burneh_clean.csv")
df_ch4 = pd.read_csv("ch4_burneh_clean.csv")

# Gabungkan berdasarkan tanggal
df_merged = (df_co
             .merge(df_no2, on='date')
             .merge(df_so2, on='date')
             .merge(df_ch4, on='date'))

df_merged.to_csv("burneh_merged.csv", index=False)
print(df_merged.head())
```

### 6. K-Means Clustering (KNIME)

Setelah data 4 polutan digabung menjadi 272 fitur per mahasiswa (hasil preprocessing polinomial), dilakukan klastering menggunakan algoritma K-Means di KNIME Analytics Platform, membandingkan 3 skenario reduksi dimensi (tanpa PCA, PCA 10 komponen, PCA 5 komponen), masing-masing diuji dengan k=3 dan k=5.

Alur Kerja (Workflow) di KNIME:
```
Excel Reader
    -> Column Filter (buang Nama, Daerah)
    -> [Skenario 1: Tanpa PCA (272 fitur) -> k-Means]
    -> [Skenario 2: PCA (10 komponen) -> k-Means]
    -> [Skenario 3: PCA (5 komponen) -> k-Means]
Tiap k-Means dijalankan k=3 dan k=5, lalu bercabang dua:
    k-Means -> Silhouette Coefficient -> Table View
    k-Means -> Joiner (+ Excel Reader) -> Python Script -> Scatter Plot
```
Catatan Implementasi KNIME: Pada Skenario 2 dan 3, opsi 'Remove original data columns' diaktifkan pada node PCA untuk memastikan fitur dimensi tinggi benar-benar tereduksi dan tidak mengalami penumpukan (lossless) seperti pada Tugas 4 sebelumnya.

[fotocollab]
(gambar: grid 6 scatter plot hasil ekspor Colab, urutan baris atas k3_nopca/k3_pca5/k3_pca10, baris bawah k5_nopca/k5_pca5/k5_pca10)

Hasil Evaluasi & Analisis Nilai Silhouette Coefficient:

| Skenario Fitur | Overall k=3 | Overall k=5 |
|---|---|---|
| Skenario 1: Tanpa PCA (272 Fitur) | 0.491 | 0.419 |
| Skenario 2: PCA 10 Komponen | 0.491 | 0.419 |
| Skenario 3: PCA 5 Komponen | 0.504 | 0.434 |

[fotosilhouseskenario1]
(gambar: Table View Silhouette - Skenario Tanpa PCA, hasil k3_nopca dan k5_nopca)

[fotosilhouseskenario2]
(gambar: Table View Silhouette - Skenario PCA 10 Komponen, hasil k3_pca10 dan k5_pca10)

[fotosilhouseskenario3]
(gambar: Table View Silhouette - Skenario PCA 5 Komponen, hasil k3_pca5 dan k5_pca5)

Catatan penting: seluruh nilai Silhouette di sini (0.419-0.504) melonjak jauh lebih tinggi dibanding Tugas 4 sebelumnya (overall hanya berkisar -0.123 s.d. 0.01). Ini bukan efek dari reduksi PCA, melainkan dampak dari preprocessing polinomial yang menciptakan struktur data jauh lebih terpisah rapi sejak awal.

Analisis Grafik Sebaran & Pembuktian Hipotesis:

A. Analisis Efek Curse of Dimensionality (Tanpa PCA)

Skenario tanpa PCA (272 fitur) tidak menunjukkan tanda curse of dimensionality yang merusak struktur data. Nilai overall silhouette-nya tetap kompetitif (0.491 pada k=3 dan 0.419 pada k=5). Ini mengindikasikan bahwa setelah preprocessing polinomial, 272 fitur asli sudah bersifat sangat informatif untuk membentuk klaster yang solid secara mandiri.

B. Pengaruh Reduksi Dimensi PCA Bertingkat (PCA 10 vs PCA 5)

1. PCA 10 Komponen: menghasilkan nilai Overall Silhouette yang identik persis dengan skenario tanpa PCA, baik pada k=3 (0.491 = 0.491) maupun k=5 (0.419 = 0.419). Ini membuktikan bahwa 10 komponen utama sudah mampu menangkap hampir seluruh variansi penting data, sehingga reduksi ke titik ini belum memberikan dampak perubahan kualitas yang berarti.
2. PCA 5 Komponen: reduksi yang lebih agresif ke 5 komponen justru memberikan peningkatan performa yang konsisten pada kedua nilai k - naik menjadi 0.504 pada k=3 (dari 0.491) dan naik menjadi 0.434 pada k=5 (dari 0.419). Ini menandakan pemangkasan dimensi lebih dalam berhasil mengeliminasi noise/variansi minor pengganggu, membuat batas klaster sedikit lebih bersih.
3. Pergeseran Anggota Klaster: pergeseran posisi titik mahasiswa terlihat jelas pada scatter plot antarskenario, membuktikan proses PCA yang dijalankan dengan opsi pembuangan kolom asli ini benar-benar bersifat lossy (berbeda dari Tugas 4 yang lossless akibat jumlah komponen PCA = 19 identik dengan jumlah sampel).

Kesimpulan:

Reduksi dimensi PCA secara bertingkat terbukti bersifat lossy dan memengaruhi persebaran keanggotaan klaster mahasiswa, dengan pola peningkatan yang konsisten di kedua nilai k. Skenario optimal terbaik secara matematis ditemukan pada Skenario PCA 5 Komponen dengan k=3, menghasilkan Overall Silhouette tertinggi sebesar 0.504.

Namun, temuan paling signifikan dari eksperimen ini adalah perbandingan inter-tugas: metode pra-pemrosesan data (kombinasi IQR iteratif + interpolasi polinomial) pada Tugas 5 terbukti memberikan pengaruh perbaikan kualitas klastering yang jauh lebih besar (melompat ke rentang 0.42-0.50) dibandingkan metode seasonal+subset-IQR pada Tugas 4 sebelumnya (bernilai negatif/mendekati 0). Ini menunjukkan bahwa ketepatan strategi pembersihan data awal memegang peran jauh lebih vital dalam menentukan keberhasilan klasterisasi dibandingkan penentuan jumlah komponen reduksi PCA itu sendiri.

# Klasifikasi Spasial Lahan Sawah dan Non-Sawah

Bagian ini mendokumentasikan tahapan akuisisi citra satelit optik **Sentinel-2A (Level-2A)** dalam format GeoTIFF (`.tif`) melalui **openEO**, ekstraksi nilai spektral seluruh piksel pada **100 poligon sampel** (50 Sawah dan 50 Non-Sawah) di **Kecamatan Baron, Kabupaten Nganjuk** yang telah dilabeli melalui **QGIS**, hingga pemodelan klasifikasi biner (2 kelas) menggunakan **Random Forest**. Evaluasi dilakukan per poligon dengan **GroupKFold** dan menghasilkan akurasi **89,04%**.

## Instalasi Library Yang Digunakan

```
pip install geopandas
```

```
pip install openeo
```

```
pip install scikit-learn
```

```
pip install rasterio
```

```
pip install matplotlib
```

## 1. Desain Pengambilan Sampel (Ground Truth)

Pengambilan sampel dilakukan secara spasial dengan membagi objek pengamatan ke dalam dua kelas seimbang (*balanced dataset*) dalam format vektor `GeoJSON`. Setiap sampel berupa poligon, bukan titik, sehingga satu sampel mencakup banyak piksel Sentinel-2.

| Kelas Target  | Kode Label | Jumlah Sampel   | Karakteristik Objek                                                         |
| ------------- | ---------- | --------------- | --------------------------------------------------------------------------- |
| **Sawah**     | `1`        | 50 Poligon      | Petak lahan persawahan; poligon bernama `s` + nomor (misal `s1`)            |
| **Non-Sawah** | `0`        | 50 Poligon      | Seluruh penutup lahan selain sawah (heterogen); poligon bernama `r` + nomor |
| **Total**     | —          | **100 Poligon** | Digabungkan menjadi satu *GeoDataFrame* berproyeksi `EPSG:4326`             |

```python
import geopandas as gpd
import openeo
import pandas as pd

# ==============================================================================
# 1. BACA GEOJSON, BERSIHKAN NAMA, DAN BERI LABEL OTOMATIS
# ==============================================================================
gdf_semua = gpd.read_file("sawah-nonsawah.geojson").to_crs("EPSG:4326")

# Bersihkan nama: hapus spasi/newline, jadikan huruf kecil agar 'S46' ikut terbaca
gdf_semua["Nama"] = gdf_semua["Nama"].astype(str).str.strip().str.lower()

# Buang baris yang bukan sampel (batas kecamatan)
gdf_semua = gdf_semua[~gdf_semua["Nama"].str.startswith("kecamatan")].copy()

# Regex: huruf s/r diikuti angka, supaya nama lain tidak ikut tertangkap
gdf_sawah = gdf_semua[gdf_semua["Nama"].str.match(r"^s\d+$")].copy()
gdf_nonsawah = gdf_semua[gdf_semua["Nama"].str.match(r"^r\d+$")].copy()

gdf_sawah["label_teks"], gdf_sawah["label"] = "Sawah", 1
gdf_nonsawah["label_teks"], gdf_nonsawah["label"] = "Non-Sawah", 0

# Gabungkan keduanya menjadi 1 GeoDataFrame (50 + 50 = 100 sampel)
gdf_gabungan = gpd.GeoDataFrame(
    pd.concat([gdf_sawah, gdf_nonsawah], ignore_index=True), crs="EPSG:4326"
)

# Cek: baris yang tidak masuk kelas mana pun (harus kosong)
sisa = gdf_semua[~gdf_semua.index.isin(list(gdf_sawah.index) + list(gdf_nonsawah.index))]
print("Tak terlabeli:", sisa["Nama"].tolist())
print(f"Sawah: {len(gdf_sawah)} | Non-Sawah: {len(gdf_nonsawah)} | Total: {len(gdf_gabungan)}")

# ==============================================================================
# 2. AMBIL BATAS KOORDINAT GABUNGAN (BOUNDING BOX) UNTUK OPENEO
# ==============================================================================
minx, miny, maxx, maxy = gdf_gabungan.total_bounds
buffer_deg = 0.005  # Margin ~500 meter agar poligon di tepi tetap masuk citra

bbox = {
    "west": float(minx - buffer_deg),
    "south": float(miny - buffer_deg),
    "east": float(maxx + buffer_deg),
    "north": float(maxy + buffer_deg),
}
print("Bounding Box Gabungan:", bbox)

# ==============================================================================
# 3. KONEKSI KE OPENEO & UNDUH SENTINEL-2A FORMAT GEOTIFF (.tif)
# ==============================================================================
conn = openeo.connect("openeo.dataspace.copernicus.eu")
conn.authenticate_oidc()  # Akan meminta login ke akun Copernicus

datacube = conn.load_collection(
    "SENTINEL2_L2A",
    spatial_extent=bbox,
    temporal_extent=["2026-05-01", "2026-09-30"],
    bands=["B02", "B03", "B04", "B08", "B11"],  # Blue, Green, Red, NIR, SWIR
    max_cloud_cover=10,
)

# Ambil median waktu agar bebas tutupan awan
composite_s2 = datacube.median_time()

nama_tif = "sentinel2_sawah_nonsawah.tif"
print("Mengunduh citra Sentinel-2A (.tif)...")
composite_s2.download(nama_tif, format="GTiff")
print(f"Berhasil diunduh: {nama_tif}")
```

**Output:**

```
Tak terlabeli: []
Sawah: 50 | Non-Sawah: 50 | Total: 100
Bounding Box Gabungan: [ISI: salin dari output notebook]
Authenticated using refresh token.
Mengunduh citra Sentinel-2A (.tif)...
Berhasil diunduh: sentinel2_sawah_nonsawah.tif
```

## 2. Akuisisi Citra Sentinel-2A (`.tif`) via openEO dan Ekstraksi Fitur

Akuisisi citra dilakukan menggunakan *bounding box* gabungan dari ke-100 poligon sampel pada koleksi **`SENTINEL2_L2A`** (*Bottom-of-Atmosphere Reflectance*) dengan batas tutupan awan maksimum `< 10%` pada periode 1 Mei 2026 sampai 30 September 2026, dan agregasi temporal `median_time()` untuk menghasilkan komposit citra bebas awan. Seluruh piksel di dalam setiap poligon kemudian diekstrak sehingga satu piksel menjadi satu baris data.

### Fitur Spektral dan Indeks Turunan yang Diekstrak:

1. **Band Spektral Utama:**

   - `B02` (*Blue* - 490 nm), `B03` (*Green* - 560 nm), `B04` (*Red* - 665 nm) untuk memisahkan vegetasi, tanah, dan air pada spektrum tampak.

   - `B08` (*Near Infrared / NIR* - 842 nm) untuk mendeteksi pantulan klorofil tanaman padi.

   - `B11` (*Short-Wave Infrared / SWIR* - 1610 nm) untuk mendeteksi kelembapan tanah dan genangan air.

2. **Normalized Difference Vegetation Index (NDVI):**

   $$\text{NDVI} = \frac{B08 - B04}{B08 + B04}$$

3. **Normalized Difference Water Index (NDWI):**

   $$\text{NDWI} = \frac{B03 - B08}{B03 + B08}$$

4. **Modified NDWI (MNDWI)**, mendeteksi air menggunakan SWIR:

   $$\text{MNDWI} = \frac{B03 - B11}{B03 + B11}$$

5. **Normalized Difference Moisture Index (NDMI)**, mendeteksi kelembapan:

   $$\text{NDMI} = \frac{B08 - B11}{B08 + B11}$$

```python
import numpy as np
import pandas as pd
import rasterio
from rasterio.mask import mask

# ==============================================================================
# 1. EKSTRAKSI SEMUA PIKSEL DI DALAM SETIAP POLIGON
# ==============================================================================
baris = []

with rasterio.open("sentinel2_sawah_nonsawah.tif") as src:
    gdf_proj = gdf_gabungan.to_crs(src.crs)  # samakan CRS dengan citra

    for idx, row in gdf_proj.iterrows():
        try:
            # nodata=0 (bukan NaN) karena citra bertipe int16
            arr, _ = mask(src, [row.geometry], crop=True, nodata=0, filled=True)
        except ValueError:
            continue  # poligon di luar citra, lewati

        arr = arr.astype(float)                     # (5 band, h, w)
        piksel = arr.reshape(arr.shape[0], -1).T    # (jumlah piksel, 5 band)
        piksel = piksel[(piksel > 0).all(axis=1)]   # buang piksel kosong/0

        # Tiap piksel jadi 1 baris, bawa ID poligon sebagai grup
        for p in piksel:
            baris.append([*p, row["label_teks"], idx])

df = pd.DataFrame(baris, columns=["B02", "B03", "B04", "B08", "B11", "Kelas", "poligon_id"])

# ==============================================================================
# 2. TAMBAHKAN FITUR INDEKS: NDVI, NDWI, MNDWI, NDMI
# ==============================================================================
df["NDVI"] = (df["B08"] - df["B04"]) / (df["B08"] + df["B04"] + 1e-6)
df["NDWI"] = (df["B03"] - df["B08"]) / (df["B03"] + df["B08"] + 1e-6)
df["MNDWI"] = (df["B03"] - df["B11"]) / (df["B03"] + df["B11"] + 1e-6)
df["NDMI"] = (df["B08"] - df["B11"]) / (df["B08"] + df["B11"] + 1e-6)

print("Jumlah piksel per kelas:\n", df["Kelas"].value_counts())
print("Jumlah poligon per kelas:\n", df.groupby("Kelas")["poligon_id"].nunique())
print(df.groupby("Kelas")[["NDVI", "NDWI", "MNDWI", "NDMI"]].agg(["mean", "std"]))
```

**Output:**

```
Jumlah piksel per kelas:
 Kelas
Non-Sawah    546
Sawah        485
Name: count, dtype: int64
Jumlah poligon per kelas:
 Kelas
Non-Sawah    50
Sawah        50
Name: poligon_id, dtype: int64
               NDVI                NDWI               MNDWI            \
               mean       std      mean       std      mean       std   
Kelas                                                                   
Non-Sawah  0.458490  0.267707 -0.476004  0.190672 -0.480469  0.117951   
Sawah      0.471581  0.095156 -0.491723  0.059725 -0.466546  0.083033   

               NDMI            
               mean       std  
Kelas                          
Non-Sawah  0.015645  0.165986  
Sawah      0.030347  0.109113  
```

Rata-rata NDVI kedua kelas hampir sama, tetapi simpangan baku Non-Sawah (0,268) jauh lebih besar daripada Sawah (0,095). Artinya kelas Non-Sawah berisi objek yang sangat beragam, dari bangunan dan jalan (NDVI rendah) hingga kebun dan semak (NDVI tinggi).

## 3. Hasil Evaluasi Klasifikasi 2 Kelas (Random Forest)

Dataset berisi **1031 piksel** (485 Sawah dan 546 Non-Sawah) yang dievaluasi menggunakan skema **GroupKFold 5-fold** dengan `poligon_id` sebagai grup. Skema ini mencegah kebocoran data: piksel dalam satu poligon saling bertetangga dan bernilai spektral sangat mirip, sehingga bila dibagi acak, piksel dari poligon yang sama dapat berada di data latih dan data uji sekaligus dan membuat akurasi terlalu optimistis. Model yang digunakan adalah Random Forest (200 pohon, `class_weight="balanced"`) dengan 9 fitur (5 band dan 4 indeks).

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold, cross_val_predict
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score

# ==============================================================================
# 1. EVALUASI RANDOM FOREST DENGAN GROUPKFOLD (5-FOLD PER POLIGON)
# ==============================================================================
fitur = ["B02", "B03", "B04", "B08", "B11", "NDVI", "NDWI", "MNDWI", "NDMI"]
X, y, grup = df[fitur], df["Kelas"], df["poligon_id"]

# CV per poligon: piksel satu poligon tidak boleh ada di train & test sekaligus
rf = RandomForestClassifier(
    n_estimators=200, class_weight="balanced", random_state=42, n_jobs=-1
)
y_pred = cross_val_predict(rf, X, y, groups=grup, cv=GroupKFold(n_splits=5))

print(f"Akurasi (GroupKFold): {accuracy_score(y, y_pred)*100:.2f}%")
print(confusion_matrix(y, y_pred))
print(classification_report(y, y_pred))

# ==============================================================================
# 2. POLIGON DENGAN AKURASI PIKSEL TERENDAH (KANDIDAT LABEL BERMASALAH)
# ==============================================================================
df["benar"] = (y_pred == y.values)
salah = df.groupby(["poligon_id", "Kelas"])["benar"].mean().reset_index()
salah["nama"] = salah["poligon_id"].map(gdf_gabungan["Nama"])
print("\nPoligon dengan akurasi piksel terendah:")
print(salah.sort_values("benar").head(10))
```

**Output:**

```
Akurasi (GroupKFold): 89.04%
[[479  67]
 [ 46 439]]
              precision    recall  f1-score   support

   Non-Sawah       0.91      0.88      0.89       546
       Sawah       0.87      0.91      0.89       485

    accuracy                           0.89      1031
   macro avg       0.89      0.89      0.89      1031
weighted avg       0.89      0.89      0.89      1031


Poligon dengan akurasi piksel terendah:
    poligon_id      Kelas     benar nama
1            1      Sawah  0.000000   s2
68          68  Non-Sawah  0.000000  r19
42          42      Sawah  0.222222  s43
0            0      Sawah  0.250000   s1
5            5      Sawah  0.333333   s6
50          50  Non-Sawah  0.500000   r1
64          64  Non-Sawah  0.500000  r15
3            3      Sawah  0.500000   s4
76          76  Non-Sawah  0.526316  r27
74          74  Non-Sawah  0.555556  r25
```

| Aktual \ Prediksi | Non-Sawah | Sawah |
| ----------------- | --------- | ----- |
| **Non-Sawah**     | 479       | 67    |
| **Sawah**         | 46        | 439   |

```python
import os
import matplotlib.colors as mcolors
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
from sklearn.metrics import ConfusionMatrixDisplay

os.makedirs("gambar", exist_ok=True)

# ==============================================================================
# A. VISUALISASI CONFUSION MATRIX & FEATURE IMPORTANCE
# ==============================================================================
# Latih model final dengan SEMUA data (CV hanya untuk evaluasi, bukan untuk peta)
model_final = RandomForestClassifier(
    n_estimators=200, class_weight="balanced", random_state=42, n_jobs=-1
)
model_final.fit(X, y)

fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))

# 1. Confusion Matrix dari prediksi GroupKFold
ConfusionMatrixDisplay.from_predictions(y, y_pred, cmap="Greens", ax=axes[0], colorbar=False)
axes[0].set_title("Confusion Matrix (GroupKFold 5-Fold, 1031 Piksel)")

# 2. Tingkat Kepentingan Fitur dari model final
importances = model_final.feature_importances_
indices = np.argsort(importances)
axes[1].barh(range(len(indices)), importances[indices], color="#2ecc71", edgecolor="black")
axes[1].set_yticks(range(len(indices)))
axes[1].set_yticklabels([fitur[i] for i in indices])
axes[1].set_xlabel("Nilai Kepentingan (Importance)")
axes[1].set_title("Kontribusi Fitur Spektral Sentinel-2A")

plt.tight_layout()
plt.savefig("gambar/evaluasi_model.png", dpi=300)
plt.show()

# ==============================================================================
# B. PETA KLASIFIKASI RASTER SELURUH CITRA
# ==============================================================================
with rasterio.open("sentinel2_sawah_nonsawah.tif") as src:
    img = src.read().astype(float)   # (5 band, h, w)
    bounds = src.bounds

b02, b03, b04, b08, b11 = img        # urutan band sama dengan saat unduh
eps = 1e-6

# Hitung indeks untuk seluruh piksel (urutan harus sama dengan `fitur`)
ndvi = (b08 - b04) / (b08 + b04 + eps)
ndwi = (b03 - b08) / (b03 + b08 + eps)
mndwi = (b03 - b11) / (b03 + b11 + eps)
ndmi = (b08 - b11) / (b08 + b11 + eps)

stack = np.stack([b02, b03, b04, b08, b11, ndvi, ndwi, mndwi, ndmi], axis=-1)
h, w, c = stack.shape
piksel_df = pd.DataFrame(np.nan_to_num(stack.reshape(-1, c)), columns=fitur)  # pakai nama kolom agar tanpa warning

pred = model_final.predict(piksel_df)
peta = np.where(pred == "Sawah", 1, 0).reshape(h, w)

plt.figure(figsize=(9, 7))
plt.imshow(peta, cmap=mcolors.ListedColormap(["#e74c3c", "#2ecc71"]),
           extent=[bounds.left, bounds.right, bounds.bottom, bounds.top])
plt.legend(handles=[mpatches.Patch(color="#2ecc71", label="Kelas 1: Sawah"),
                    mpatches.Patch(color="#e74c3c", label="Kelas 0: Non-Sawah")], loc="upper right")
plt.title("Peta Klasifikasi Sawah vs Non-Sawah (Sentinel-2A)", fontsize=12, fontweight="bold")
plt.xlabel("Koordinat X / Longitude")
plt.ylabel("Koordinat Y / Latitude")
plt.tight_layout()
plt.savefig("gambar/peta_klasifikasi_raster_sawah.png", dpi=300)
plt.show()
```

**Output:**

![Confusion Matrix dan Feature Importance](gambar/evaluasi_model.png)

![Peta Klasifikasi Sawah vs Non-Sawah](gambar/peta_klasifikasi_raster_sawah.png)

## 4. Analisis dan Pembahasan

### 4.1 Hasil Utama

Model memperoleh akurasi **89,04%** dengan precision dan recall yang relatif seimbang antarkelas (0,87 sampai 0,91). Terdapat 67 piksel Non-Sawah yang diprediksi sebagai Sawah dan 46 piksel Sawah yang diprediksi sebagai Non-Sawah. Kesalahan yang hampir seimbang menunjukkan model tidak condong ke satu kelas.

### 4.2 Perbandingan dengan Percobaan Awal

Percobaan awal mengambil satu piksel di titik tengah (*centroid*) setiap poligon dan membagi data secara acak 80:20. Hasilnya hanya 70%, dengan 5 dari 10 sampel Non-Sawah salah diprediksi.

| Aspek                    | Percobaan awal                  | Pendekatan akhir                        |
| ------------------------ | ------------------------------- | --------------------------------------- |
| Unit data                | 1 piksel (centroid) per poligon | Seluruh piksel di dalam poligon         |
| Jumlah data              | 100 sampel                      | 1031 piksel dari 100 poligon            |
| Skema evaluasi           | *Hold-out* 80:20 (20 data uji)  | GroupKFold 5-fold per poligon           |
| Fitur                    | 5 band, NDVI, NDWI              | 5 band, NDVI, NDWI, MNDWI, NDMI         |
| Akurasi                  | 70%                             | 89,04%                                  |

Kedua angka tidak sepenuhnya sebanding karena skema evaluasinya berbeda. Namun, evaluasi awal hanya memakai 20 data uji, sehingga satu kesalahan prediksi mengubah akurasi sebesar 5 poin dan hasilnya tidak stabil. Centroid juga berisiko jatuh di pematang atau tepi objek sehingga mewakili poligon dengan buruk.
