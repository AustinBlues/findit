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
            klass.instance_variable_set(:@title, 'Closest bicycle thefts')
            klass.instance_variable_set(:@rectype, type)
            
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
          begin
            sth = @db.execute(%q{SELECT *,
            Distance(the_geom, PointFromText(?, 4326)) AS distance,
            X(Transform(the_geom, 4326)) AS longitude,
            Y(Transform(the_geom, 4326)) AS latitude
            FROM austin_ci_tx_us_apd_incident
            WHERE crime_type = ?
            ORDER BY distance ASC
            LIMIT 5
            }, "POINT(#{origin.lng} #{origin.lat})", @rectype)
          rescue
            puts "EXCEPTION(#{__FILE__}: #{__LINE__}): #{$!.inspect}."
          end

          records = sth.fetch(:all)
          sth.finish

          return nil unless records  

          records.map{|rec| new(FindIt::Location.new(rec[8], rec[7], :DEG),
                                :title => @title,
                                :address => rec[4].capitalize_words,
                                :city => 'Austin',
                                :state => 'TX',
                                :note => rec[2],	# date
                                :origin => origin
                                )
          }
        end
        
      end # class AbstractIncident
      
    end # module Austin_CI_TX_US
  end # module Feature
end # module FindIt
