#require 'rubygems'
require 'socrata'
require 'rdbi-driver-sqlite3'

ONE_MONTH = 30 * 24 * 60 * 60	# in seconds


# Austin Police Dept (APD) Incident data URL and ID
APD_INCIDENT = 'http://data.austintexas.gov/'
ID = 'b4y9-5x39'


# Austin Police Department Socrata column name to database field mapping
APD2DB_MAP = {
  'Incident Report Number' => 'uid',
  'Crime Type' => 'crime_type',
  'Date' => 'date',
  'Time' => 'time',
  # This appears to be backwards
#  'LATITUDE' => 'latitude',
#  'LONGITUDE' => 'longitude'
  'LATITUDE' => 'longitude',
  'LONGITUDE' => 'latitude',
  'ADDRESS' => 'address'
}

api = Socrata.new(:base_uri => APD_INCIDENT)
view = api.view(ID)

# APD Socrata mapping
apd_position = {}	# Column Name to position map
apd_data_type = {}	# Column Name to data type map
view.columns.each do |col|
  # 7 extra columns at beginning, reason unknown to me (AustinBlues)
  apd_position[col['name']] = col['position']+7
  apd_data_type[col['name']] = col['dataTypeName']
end

# Cycle Nearby (CN) SQLite3 database column to position mapping
dbh = RDBI.connect(:SQLite3, :database => 'cycle_nearby.db')
cn_position = {}
columns = dbh.table_schema('austin_ci_tx_us_apd_incident').columns
columns.each_with_index do |col, i|
  cn_position[col.name.to_s] = i
end

# Only rows with 'THEFT OF BICYCLE' Crime Type in the last month
crime_type_id = view.columns.find{|c| c['name'] == 'Crime Type'}['id']
date_id = view.columns.find{|c| c['name'] == 'Date'}['id']

tob = view.filter(:filterCondition => {:type => 'operator',
		    :value => 'AND',
		    :children => [
		      {:type => 'operator',
			:value => 'EQUALS',
			:children => [
			  {:columnId =>  crime_type_id, :type => 'column'},
			  {:type => 'literal', :value => 'THEFT OF BICYCLE'}
			]
		      },
		      {:type => 'operator',
			:value => 'GREATER_THAN_OR_EQUALS',
			:children => [
			  {:columnId => date_id, :type => 'column'},
			  {:type => 'literal',
			    :value => Time.now.to_i - ONE_MONTH
			  }
			]
		      }
		    ]
		  }
		  )

total_records = 0
new_records = 0
tob.each do |row|
  if row[apd_position['LATITUDE']] && row[apd_position['LONGITUDE']]
    sql = 'SELECT uid FROM austin_ci_tx_us_apd_incident WHERE uid = ?'
    result = dbh.execute(sql, row[apd_position['Incident Report Number']])
    if result.fetch[0].empty?
      values = Array.new(APD2DB_MAP.size)
      APD2DB_MAP.each do |apd, cn|
	value = row[apd_position[apd]]
	values[cn_position[cn]] = case apd_data_type[apd]
				  when 'text'
				    "'#{value}'"
				  when 'date'
				    "'#{Time.at(value).strftime('%Y-%m-%d')}'"
				  else
				    value
				  end
      end

      sql = "INSERT INTO austin_ci_tx_us_apd_incident VALUES(#{values.join(', ')})"
      result = dbh.execute(sql)
      new_records += 1
    end
    total_records += 1
  end
end
puts "#{new_records} new records out of #{total_records} total."
dbh.disconnect
