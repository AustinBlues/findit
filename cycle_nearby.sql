CREATE TABLE austin_ci_tx_us_apd_incident (
  uid varchar(11) primary key,
  crime_type varchar,
  date date,
  time integer,
  address varchar
);
SELECT AddGeometryColumn('austin_ci_tx_us_apd_incident', 'the_geom', 4326, 'POINT', 2);
CREATE INDEX idx_austin_ci_tx_us_apd_incident_the_geom ON austin_ci_tx_us_apd_incident(the_geom);
CREATE INDEX idx_austin_ci_tx_us_apd_incident_crime_type ON austin_ci_tx_us_apd_incident(crime_type);
