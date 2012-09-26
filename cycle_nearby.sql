CREATE TABLE austin_ci_tx_us_incident (
  uid varchar(11) primary key,
  crime_type varchar,
  latitude float,
  longitude float,
  date date,
  time integer,
  address varchar
);
