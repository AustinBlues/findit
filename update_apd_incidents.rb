#require 'rubygems'
require 'socrata'
require 'rdbi-driver-sqlite3'

# How old data to use
HORIZON = 30 * 24 * 60 * 60	# One month in seconds

# Austin Police Dept (APD) Incident data URL and ID
APD_INCIDENT = 'http://data.austintexas.gov/'
ID = 'b4y9-5x39'

# Austin Police Department Socrata column name to database field mapping
APD2DB_MAP = {
  'Incident Report Number' => 'uid',
  'Crime Type' => 'crime_type',
  'Date' => 'date',
  'Time' => 'time',
  'ADDRESS' => 'address'
}


# Convert from Socrata formatting to SQL VALUES formatting
def socrata2sql(value, data_type)
  case data_type
  when 'text'
    "'#{value}'"
  when 'date'
    "'#{Time.at(value).strftime('%Y-%m-%d')}'"
  else
    value
  end
end


# Only rows with 'THEFT OF BICYCLE' Crime Type in the last month
def theft_of_bicycle(view)
  crime_type_id = view.columns.find{|c| c['name'] == 'Crime Type'}['id']
  date_id = view.columns.find{|c| c['name'] == 'Date'}['id']

  view.filter(:filterCondition => {:type => 'operator',
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
			:value => Time.now.to_i - HORIZON
		      }
		    ]
		  }
		]
	      }
  )
end


# APD Socrata mapping
view = Socrata.new(:base_uri => APD_INCIDENT).view(ID)
apd_position = {}	# Column Name to position map
apd_data_type = {}	# Column Name to data type map
view.columns.each do |col|
  # 7 extra columns at beginning, reason unknown to me (AustinBlues)
  apd_position[col['name']] = col['position']+7
  apd_data_type[col['name']] = col['dataTypeName']
end

# Cycle Nearby (CN) SQLite3 database column to position mapping
dbh = RDBI.connect(:SQLite3, :database => 'cycle_nearby.db')
# Load spatialite extension
dbh.handle.enable_load_extension(true)
dbh.handle.load_extension('/usr/lib/libspatialite.so')
cn_position = {}
columns = dbh.table_schema('austin_ci_tx_us_apd_incident').columns
columns.each_with_index do |col, i|
  cn_position[col.name.to_s] = i
end

total_records = 0
new_records = 0
dbh.prepare('SELECT uid FROM austin_ci_tx_us_apd_incident WHERE uid = ?') do |sth|
  theft_of_bicycle(view).each do |row|
    latitude = row[apd_position['LATITUDE']]
    longitude = row[apd_position['LONGITUDE']]
    if latitude && longitude
      result = sth.execute(row[apd_position['Incident Report Number']])
      if result.fetch[0].empty?
	values = Array.new(APD2DB_MAP.size+1)
	APD2DB_MAP.each do |apd, cn|
	  values[cn_position[cn]] = socrata2sql(row[apd_position[apd]], apd_data_type[apd])
	end
        values[-1] = "GeomFromText('POINT(#{longitude} #{latitude})', 4326)"
        sql = "INSERT INTO austin_ci_tx_us_apd_incident VALUES(#{values.join(', ')})"
        puts "SQL: #{sql};"
        dbh.execute(sql)
	new_records += 1
      end
      total_records += 1
    end
  end
end

puts "#{new_records} new records out of #{total_records} total."

# Delete old records
dbh.execute('DELETE FROM austin_ci_tx_us_apd_incident WHERE date < ?',
                     (Time.now - 24 * 60 * 60).strftime('%Y-%m-%d'))

dbh.disconnect
