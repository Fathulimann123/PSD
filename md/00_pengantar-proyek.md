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
