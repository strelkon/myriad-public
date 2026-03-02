DROP MATERIALIZED VIEW IF EXISTS sbs_na_sca_a64;
CREATE MATERIALIZED VIEW sbs_na_sca_a64 AS (
WITH sbs AS (
SELECT nace, geo, indic_sb, time, sum(value) AS value FROM sbs_na_sca_r2 
JOIN nace64 ON nace_r2::text ~ nace64.regex
WHERE nace_r2 NOT IN (SELECT nace from nace64) AND nace NOT IN (SELECT nace_r2 FROM sbs_na_sca_r2) and nace NOT IN ('O','P','Q','T','U')
GROUP BY nace, geo, indic_sb, time
UNION
SELECT nace, geo, indic_sb, time, value FROM sbs_na_sca_r2 
JOIN nace64 ON nace_r2=nace64.nace
),
foo AS (
WITH sbs_geo AS (SELECT DISTINCT geo FROM sbs_na_sca_r2), 
sbs_indic AS (SELECT DISTINCT indic_sb FROM sbs_na_sca_r2), 
sbs_time AS (SELECT DISTINCT time FROM sbs_na_sca_r2) 
SELECT nace64.nace, sbs_geo.geo, sbs_indic.indic_sb, sbs_time.time FROM nace64, sbs_geo, sbs_indic, sbs_time
)
SELECT foo.nace AS nace_r2, foo.geo, foo.indic_sb, foo.time, value FROM foo 
LEFT JOIN sbs ON foo.nace=sbs.nace AND foo.geo=sbs.geo AND foo.indic_sb=sbs.indic_sb AND foo.time=sbs.time
WHERE foo.nace NOT IN ('L68A','T','U') 
ORDER BY foo.nace
);
