CREATE TABLE austin_ci_tx_us_apd_incident (
  uid varchar(11) primary key,
  crime_type varchar,
  latitude float,
  longitude float,
  date date,
  time integer,
  address varchar
);
SELECT AddGeometryColumn('austin_ci_tx_us_apd_incident', 'the_geom', 4326, 'POINT', 2);
