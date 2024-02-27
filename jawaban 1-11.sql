#1. Tampilkan nama cabang dan nama kota yang punya data penjualan
select distinct nama_cabang , nama_kota
from tr_penjualan tp 
inner join ms_cabang mc 
on tp.kode_cabang = mc.kode_cabang 
inner join ms_kota mk 
on mk.kode_kota = mc.kode_kota ;

#2. Tampilkan nama cabang dan nama kota dari cabang yang tidak punya data penjualan di kota yang ada data penjualan (dari cabang lain)
select distinct mc.nama_cabang,mk.nama_kota
from ms_cabang mc
left join ms_kota mk
on mc.kode_kota = mk.kode_kota 
left join tr_penjualan tp
on mc.kode_cabang = tp.kode_cabang
where mk.nama_kota in ( select distinct nama_kota
						from tr_penjualan tp 
						inner join ms_cabang mc 
						on tp.kode_cabang = mc.kode_cabang 
						inner join ms_kota mk 
						on mk.kode_kota = mc.kode_kota
)
and tp.jumlah_pembelian is null;

# 3. Tampilkan nama kota, group cabang yang berjualan dan group cabang yang tidak berjualan untuk kota yang ada data penjualan (Untuk PR). Clue: Gunakan group_concat 
with t1 as (
			select distinct nama_cabang , nama_kota
			from tr_penjualan tp 
			inner join ms_cabang mc 
			on tp.kode_cabang = mc.kode_cabang 
			inner join ms_kota mk 
			on mk.kode_kota = mc.kode_kota
			order by nama_cabang asc
), t2 as (
			select distinct mc.nama_cabang,mk.nama_kota
			from ms_cabang mc
			left join ms_kota mk
			on mc.kode_kota = mk.kode_kota 
			left join tr_penjualan tp
			on mc.kode_cabang = tp.kode_cabang
			where tp.jumlah_pembelian is null and mk.nama_kota in (
									select distinct nama_kota
									from tr_penjualan tp 
									inner join ms_cabang mc 
									on tp.kode_cabang = mc.kode_cabang 
									inner join ms_kota mk 
									on mk.kode_kota = mc.kode_kota)
			order by nama_cabang asc
)
select t1.nama_kota as nama_kota, group_concat(distinct t1.nama_cabang) as nacab_jualan, group_concat(t2.nama_cabang) as nacab_tidak_jualan
from t1
inner join t2
on t1.nama_kota = t2.nama_kota
group by t1.nama_kota;


#4. Ada berapa produk yang dijual kasir 039-127 di tanggal 8 Agustus 2008?
select count(distinct kode_produk) as jumlah_kasir_039127
from tr_penjualan tp 
where kode_kasir = '039-127' and  date(tgl_transaksi) = '2008-08-08';

#5. Ada berapa cabang di Provinsi Yogyakarta? 
select count(distinct nama_cabang) as jumlah_cabang_DI_Yogyakarta
from ms_cabang mc 
inner join ms_kota mk 
on mc.kode_kota = mk.kode_kota 
inner join ms_propinsi mp 
on mk.kode_propinsi = mp.kode_propinsi
where mp.nama_propinsi  = 'DI Yogyakarta';

#6. Berapa total keuntungan yang didapat pada tanggal 8 Agustus 2008 pada cabang Makassar 01
#cara 1
select sum(tp.jumlah_pembelian*(mhh.harga_berlaku_cabang-(mhh.modal_cabang+mhh.biaya_cabang))) as total_keuntungan
from ms_harga_harian mhh 
inner join ms_cabang mc 
on mhh.kode_cabang = mc.kode_cabang 
inner join tr_penjualan tp 
on tp.kode_produk = mhh.kode_produk and date(tp.tgl_transaksi) = date(mhh.tgl_berlaku) and tp.kode_cabang = mhh.kode_cabang 
where date(mhh.tgl_berlaku) = '2008-08-08' and mc.nama_cabang like '%Makassar 01%'
;
#cara 2
select sum(tp.jumlah_pembelian*(mhh.harga_berlaku_cabang-(mhh.modal_cabang+mhh.biaya_cabang))) as total_keuntungan
from ms_harga_harian mhh 
inner join ms_cabang mc 
on mhh.kode_cabang = mc.kode_cabang 
inner join tr_penjualan tp 
on tp.kode_produk = mhh.kode_produk and tp.kode_cabang = mhh.kode_cabang
where date(mhh.tgl_berlaku) = '2008-08-08' 
		and mc.nama_cabang like '%Makassar 01%' 
		and date(tp.tgl_transaksi) = '2008-08-08'
		and tp.kode_cabang = mhh.kode_cabang
;

#7. Tampilkan total transaksi per–kasir, dan bandingkan dengan total per–cabang.
with t1 as (
			select kode_kasir, count(kode_transaksi) as total_transaksi_kasir
			from tr_penjualan tp 
			group by 1
), t2 as (
			select kode_cabang,count(kode_transaksi) as total_transaksi_cabang
			from tr_penjualan tp 
			group by 1
)
select t1.*,t2.*
from t2
cross join t1
;

#8. Lakukan analisa produk mana saja yang termasuk di grup yang memiliki sedikit penjualan dibandingkan dengan keseluruhan produk. 
#Bagi menjadi 4 kelompok besar, dan filter 2 kelompok besar terbawah untuk melihat produk mana saja
with t1 as (
		select * from tr_penjualan tp
), t2 as (
		select * from ms_harga_harian mhh
), t3 as (
		select * from ms_produk mp
), t4 as (
select distinct t1.kode_cabang,t3.nama_produk, 
sum(t1.jumlah_pembelian * (t2.harga_berlaku_cabang-(t2.modal_cabang+t2.biaya_cabang))) as profit,
NTILE(4) OVER (ORDER BY sum(t1.jumlah_pembelian * (t2.harga_berlaku_cabang-(t2.modal_cabang+t2.biaya_cabang))) desc) AS quartile
from t1
inner join t2
on t1.kode_produk = t2.kode_produk and date(t1.tgl_transaksi) = date(t2.tgl_berlaku) and t1.kode_cabang = t2.kode_cabang
inner join t3
on t1.kode_produk = t3.kode_produk
group by 1,2
order by 1,2 asc
)
select *
from t4
where quartile >= 3
order by profit desc;

#9. Urutkan 3 kota dengan penjualan terbanyak, 
#hitung dengan melihat rate penjualan kota dibandingkan dengan keseluruhan toko selama Q1 2028
#pertanyaan dengan jawaban yang ada di ppt berbeda, jadi saya mencoba mengikuti jawaban
with t1 as (
		select mk.nama_kota as nama_kota, count(distinct tp.kode_cabang) as total_cabang,sum(tp.jumlah_pembelian) as jumlah_penjualan_cabang
		from tr_penjualan tp 
		inner join ms_cabang mc 
		on tp.kode_cabang = mc.kode_cabang 
		inner join ms_kota mk 
		on mc.kode_kota = mk.kode_kota
		inner join ms_harga_harian mhh 
		on date(tp.tgl_transaksi) = date(mhh.tgl_berlaku) and tp.kode_produk = mhh.kode_produk and tp.kode_cabang = mhh.kode_cabang
		where tgl_transaksi >= '2008-01-01' AND tgl_transaksi <= '2008-06-30'
		group by 1
),
t2 as (
		select distinct mk.nama_kota as nama_kota, sum(tp.jumlah_pembelian) over() as jumlah_penjualan_keseluruhan_cabang
		from tr_penjualan tp 
		right join ms_cabang mc 
		on tp.kode_cabang = mc.kode_cabang 
		right join ms_kota mk 
		on mc.kode_kota = mk.kode_kota
		where tgl_transaksi >= '2008-01-01' AND tgl_transaksi <= '2008-06-30'
),
t3 as (
		select t1.*,t2.jumlah_penjualan_keseluruhan_cabang as jumlah_penjualan_keseluruhan_cabang
		from t1
		inner join t2
		on t1.nama_kota = t2.nama_kota
)
select t3.*,round((100*t3.jumlah_penjualan_cabang/t3.jumlah_penjualan_keseluruhan_cabang),2) as rate, rank() over(order by t3.jumlah_penjualan_cabang desc) as urutan
from t3;

#10. Sebagai seorang analyst kalian bertugas monitor performa setiap cabang. 
#Bandingkan performa setiap cabang setiap bulannya selama 2008 dan lihat bagaimana trendnya.
with t1 as (
			select month(date(tgl_transaksi)) as bulan,kode_cabang, count(distinct kode_transaksi) as jumlah_transaksi
			from tr_penjualan tp
			group by 1,2
			order by 2,1
), 
t2 as ( 
			select t1.*,lag(t1.jumlah_transaksi) over(partition by t1.kode_cabang) as jumlah_transaksi_sebelumnya
			from t1
)
select t2.*,(100*(t2.jumlah_transaksi-t2.jumlah_transaksi_sebelumnya)/t2.jumlah_transaksi_sebelumnya) as rate,
case 
	when (100*(t2.jumlah_transaksi-t2.jumlah_transaksi_sebelumnya)/t2.jumlah_transaksi_sebelumnya) < 0 then 'Negatif'
	when (100*(t2.jumlah_transaksi-t2.jumlah_transaksi_sebelumnya)/t2.jumlah_transaksi_sebelumnya) > 0 then 'Positif'
	else 'No Data'
end as keterangan
from t2
;

#11. Sebagai seorang HRD analyst kalian ingin melihat karyawan mana dari setiap cabang yang memilik penjualan terbanyak selama Q1 2008. 
#Temukan top 3 dari masing-masing cabang	
with t1 as (
			select mc.kode_cabang,mk2.nama_kota, concat(mk.nama_depan,mk.nama_belakang) as nama_panjang, sum(tp.jumlah_pembelian) as jumlah_penjualan	
			from tr_penjualan tp 
			inner join ms_cabang mc 
			on tp.kode_cabang = mc.kode_cabang 
			inner join ms_karyawan mk 
			on tp.kode_kasir = mk.kode_karyawan and mc.kode_cabang = mk.kode_cabang
			inner join ms_kota mk2
			on mc.kode_kota = mk2.kode_kota
			where tgl_transaksi >= '2008-01-01' and tgl_transaksi <= '2008-06-30'
			group by 1,2,3
),
t1_1 as (
			select t1.kode_cabang, sum(t1.jumlah_penjualan) as jumlah_penjualan_cabang
			from t1
			group by 1
),
t1_merge as (
				select t1.*,round(100*(t1.jumlah_penjualan/t1_1.jumlah_penjualan_cabang),2) as rate
				from t1
				inner join t1_1
				on t1.kode_cabang = t1_1.kode_cabang
),
t2 as (
			select t1_merge.*,rank() over(partition by t1_merge.nama_kota order by t1_merge.rate desc) as urutan
			from t1_merge
)
select t2.*
from t2
where t2.urutan <= 3
;