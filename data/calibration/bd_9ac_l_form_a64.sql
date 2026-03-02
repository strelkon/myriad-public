DROP MATERIALIZED VIEW IF EXISTS bd_9ac_l_form_a64;
CREATE MATERIALIZED VIEW bd_9ac_l_form_a64 AS (
WITH sbs AS (
SELECT nace, geo, indic_sb, leg_form, time, sum(value) AS value FROM bd_9ac_l_form_r2 
JOIN nace64 ON nace_r2::text ~ nace64.regex
WHERE nace_r2 NOT IN (SELECT nace from nace64) AND nace NOT IN (SELECT nace_r2 FROM bd_9ac_l_form_r2) AND nace_r2 !~ '^([A-Z][0-9][0-9][0-9])' 
GROUP BY nace, geo, indic_sb, leg_form, time
UNION
SELECT nace, geo, indic_sb, leg_form, time, value FROM bd_9ac_l_form_r2 
JOIN nace64 ON nace_r2=nace64.nace
),
foo AS (
WITH sbs_geo AS (SELECT DISTINCT geo FROM bd_9ac_l_form_r2), 
sbs_indic AS (SELECT DISTINCT indic_sb FROM bd_9ac_l_form_r2), 
sbs_leg AS (SELECT DISTINCT leg_form FROM bd_9ac_l_form_r2), 
sbs_time AS (SELECT DISTINCT time FROM bd_9ac_l_form_r2) 
SELECT nace64.nace, sbs_geo.geo, sbs_indic.indic_sb, sbs_leg.leg_form, sbs_time.time FROM nace64, sbs_geo, sbs_indic, sbs_leg, sbs_time
)
SELECT foo.indic_sb, foo.leg_form, foo.nace AS nace_r2, foo.geo, foo.time, value FROM foo 
LEFT JOIN sbs ON foo.nace=sbs.nace AND foo.geo=sbs.geo AND foo.indic_sb=sbs.indic_sb AND foo.leg_form=sbs.leg_form AND foo.time=sbs.time
WHERE foo.nace NOT IN ('L68A','T','U') 
ORDER BY foo.nace
);
