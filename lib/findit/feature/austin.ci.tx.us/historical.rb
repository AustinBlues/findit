require 'findit'

module FindIt
  module Feature
    module Austin_CI_TX_US      

      class HistoricalFactory
        
        def self.create(db, type, options = {})
          klass = Class.new(AbstractHistorical)
          klass.instance_variable_set(:@db, db)
          klass.instance_variable_set(:@type, type)
          case type
            
          when :MOON_TOWER
            klass.instance_variable_set(:@marker, FindIt::Asset::MapMarker.new(
              "http://maps.google.com/mapfiles/kml/pal3/icon40.png",
              :shadow => "icon40s.png"))
            klass.instance_variable_set(:@title, "Closest moon tower")
            klass.instance_variable_set(:@rectype, "MOONLIGHT TOWERS")            
            
          else
            raise "unknown historical type \"#{type}\""
            
          end
          
          klass          
        end # initialize
        
      end # class HistoricalFactory
      
      
      class AbstractHistorical < FindIt::BaseFeature
        
        @db = nil
        @title = nil
        @rectype = nil
                         

        def self.closest(origin)
          begin
            sth = @db.execute(%q{SELECT *,
            X(Transform(the_geom, 4326)) AS longitude,
            Y(Transform(the_geom, 4326)) AS latitude,
            Distance(Transform(the_geom, 4326), PointFromText(?, 4326)) AS distance
            FROM austin_ci_tx_us_historical
            WHERE building_n = ?
            ORDER BY distance ASC
            LIMIT 1
          }, "POINT(#{origin.lng} #{origin.lat})", @rectype)
          rescue
            puts "EXCEPTION(#{__FILE__}: #{__LINE__}): #{$!.inspect}."
          end

          rec = sth.fetch[0]	# FIXME? only using one of potentially many
          sth.finish

          return nil unless rec  
          
          new(FindIt::Location.new(rec[14], rec[13], :DEG),
            :title => @title,
            :address => rec[11].capitalize_words,
            :city => "Austin",
            :state => "TX",
            :origin => origin
          )
        end
        
      end # class AbstractHistorical
      
    end # module Austin_CI_TX_US
  end # module Feature
end # module FindIt
