require "rdbi-driver-sqlite3"

module FindIt
  
  # This module can be included in "Find It" Rakefile's
  # that manage data sources.
  #
  # They typically are found in: findit/local/<i>locality</i>/data/<i>dataset</i>
  #
  module RakeDefs
    
    # Connection to the SQLite3/spatialite database.
    #
    begin
      DB = RDBI.connect(:SQLite3,
                        :database => File.expand_path('cycle_nearby.db',
                                                      '../../../../../..'))
      DB.handle.enable_load_extension(true)
      DB.handle.load_extension('/usr/lib/libspatialite.so')
    rescue
      puts "DB EXCEPTION: #{$!}."
    end

    # Execute a SQL command on the connected database.
    #
    # Displays command to stderr.
    #
    def self.db_execute(cmd)
      $stderr.puts("+ " + cmd)
      DB.execute(cmd)
    end
    
    # Run the "shp2pgsql" command on a shape file and load the output.
    def self.db_load_shapefile(table, shapefile, srid)
      db_path = '../../../../../../cycle_nearby.db'
      result = `spatialite_tool -i -shp #{shapefile} -d #{db_path} -t #{table} -2 -c ASCII -s #{srid} -g the_geom`
#      puts "SHELL: #{result}"
    end
    
    def self.db_create_index(table, column)
      db_execute("CREATE INDEX idx_#{table}_#{column} ON #{table} (#{column})")
    end
    
    def self.db_vacuum(table)
      db_execute("VACUUM")
    end
    
    def self.db_table_exists?(table)
      !DB.table_schema(table).nil?
    end
      
    def self.db_drop_table(table)
      db_execute("DROP TABLE #{table}")
    end

  end # module RakeDefs
end # module FindIt
  
