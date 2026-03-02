DELETE FROM nama_10_a64 where value IS NULL;
WITH foo AS (
	WITH na_item AS (SELECT DISTINCT na_item FROM nama_10_a64),
	geo AS (SELECT DISTINCT geo FROM nama_10_a64),
	time AS (SELECT DISTINCT time FROM nama_10_a64 WHERE geo='AT'), 
	nace AS (SELECT nace FROM nace64)
	SELECT 'CP_MEUR' AS unit, nace.nace AS nace_r2, na_item.na_item, geo.geo, time.time FROM na_item, geo, time, nace
)
INSERT INTO nama_10_a64 
SELECT 'A', foo.*, NULL AS value FROM foo
LEFT JOIN nama_10_a64 ON foo.unit=nama_10_a64.unit AND foo.na_item=nama_10_a64.na_item AND foo.geo=nama_10_a64.geo AND foo.time=nama_10_a64.time AND foo.nace_r2=nama_10_a64.nace_r2
WHERE nama_10_a64.value IS NULL;


DELETE FROM nama_10_a64_e where value IS NULL;
WITH foo AS (
	WITH unit AS (SELECT DISTINCT unit FROM nama_10_a64_e WHERE unit IN ('THS_PER', 'THS_JOB')), 
	nace AS (SELECT nace FROM nace64), 
	na_item AS (SELECT DISTINCT na_item FROM nama_10_a64_e),
	geo AS (SELECT DISTINCT geo FROM nama_10_a64_e),
	time AS (SELECT DISTINCT time FROM nama_10_a64_e WHERE geo='AT') 
	SELECT unit.unit, nace.nace AS nace_r2, na_item.na_item, geo.geo, time.time FROM unit, nace, na_item, geo, time
)
INSERT INTO nama_10_a64_e 
SELECT 'A', foo.unit, foo.nace_r2, foo.na_item, foo.geo, foo.time, NULL AS value FROM foo 
LEFT JOIN nama_10_a64_e ON foo.unit=nama_10_a64_e.unit AND foo.nace_r2=nama_10_a64_e.nace_r2 AND foo.na_item=nama_10_a64_e.na_item AND foo.geo=nama_10_a64_e.geo AND foo.time=nama_10_a64_e.time
WHERE nama_10_a64_e.value IS NULL;