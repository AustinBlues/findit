require 'findit'

module FindIt
  module Feature
    module Austin_CI_TX_US      

      class IncidentFactory
        
        def self.create(db, type, options = {})
          klass = Class.new(AbstractIncident)
          klass.instance_variable_set(:@db, db)
          klass.instance_variable_set(:@type, type)
          case type
            
          when 'THEFT OF BICYCLE'
            klass.instance_variable_set(:@marker, FindIt::Asset::MapMarker.new(
              'http://maps.google.com/mapfiles/kml/pal3/icon33.png',
              :shadow => 'icon33s.png'))
            klass.instance_variable_set(:@title, 'Latest bicycle theft')
            klass.instance_variable_set(:@rectype, 'THEFT OF BICYCLE')            
            
          else
            raise "unknown incident type \"#{type}\""
            
          end
          
          klass          
        end # initialize
        
      end # class IncidentFactory
      
      
      class AbstractIncident < FindIt::BaseFeature
        @db = nil
        @title = nil
        @rectype = nil
                         
        def self.closest(origin)
	  if false
	    # Only the latest bike theft - arbitrary, but should change daily.
            if false
              fields = 'uid, crime_type, latitude, longitude, date, time, address'
            else
              fields = '*'
            end
            sql = "SELECT #{fields} FROM austin_ci_tx_us_apd_incident ORDER BY date DESC LIMIT 1"
	    sth = @db.execute(sql)
	  else
            puts "LONG: #{origin.lng}, LAT: #{origin.lat}."
            begin
              if true
                sql = %Q{SELECT *,
            Distance(geometry, PointFromText('POINT(#{origin.lat} #{origin.lng})', 4326)) AS distance
            FROM austin_ci_tx_us_apd_incident
            ORDER BY distance ASC
            LIMIT 1
            }
                puts "SQL: #{sql};"
                sth = @db.execute(sql)
              else
                sth = @db.execute(%q{SELECT *,
            X(Transform(geometry, 4326)) AS longitude,
            Y(Transform(geometry, 4326)) AS latitude,
            Distance(Transform(geometry, 4326), GeomFromText('POINT(? ?)', 4326)) AS distance
            FROM austin_ci_tx_us_apd_incident
            ORDER BY distance ASC
            LIMIT 1
            }, origin.lat.to_s, origin.lng.to_s)
              end
            rescue
#              puts "SQL: #{@db.last_statement.query};"
              puts "EXCEPTION(#{__FILE__}: #{__LINE__}): #{$!}."
            end
	  end
          rec = sth.fetch[0]	  # FIXME: only using first of potentially many
          sth.finish

          puts "REC: #{rec.inspect}."

          return nil unless rec  
          
          loc = new(FindIt::Location.new(rec[2], rec[3], :DEG),
            :title => @title,
            :address => rec[6].capitalize_words,
            :city => 'Austin',
            :state => 'TX',
            :origin => origin
          )
          puts "LOC: #{loc.inspect}."
	  loc
        end
        
        
      end # class AbstractIncident
      
    end # module Austin_CI_TX_US
  end # module Feature
end # module FindIt
