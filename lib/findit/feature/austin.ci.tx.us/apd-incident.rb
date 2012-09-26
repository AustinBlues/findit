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
            klass.instance_variable_set(:@title, 'Closest bicycle theft')
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
	  if true
	    sth = @db.execute('SELECT * FROM austin_ci_tx_us_apd_incident LIMIT 1')
	  else
	    sth = @db.execute(%q{SELECT *,
            ST_X(ST_Transform(the_geom, 4326)) AS longitude,
            ST_Y(ST_Transform(the_geom, 4326)) AS latitude,
            ST_Distance(ST_Transform(the_geom, 4326), ST_SetSRID(ST_Point(?, ?), 4326)) AS distance
            FROM austin_ci_tx_us_incident
            WHERE building_n = ?
            ORDER BY distance ASC
            LIMIT 1
            }, origin.lng, origin.lat, @rectype)
	  end
          rec = sth.fetch[0]	  # FIXME: only using first of potentially many
          sth.finish

          return nil unless rec  
          
          loc = new(FindIt::Location.new(rec[2], rec[3], :DEG),
            :title => @title,
            :address => rec[6].capitalize_words,
            :city => 'Austin',
            :state => 'TX',
            :origin => origin
          )
	  loc
        end
        
        
      end # class AbstractIncident
      
    end # module Austin_CI_TX_US
  end # module Feature
end # module FindIt
