require 'findit/base-feature'

module FindIt
  module Feature
    module Travis_CO_TX_US
      class VotingPlace < FindIt::BaseFeature        

        def self.type
          :VOTING_PLACE
        end  

        MARKER = FindIt::Feature::MapMarker.new(
          "/mapicons/vote_icon.png",
          :height => 32, :width => 32).freeze
          
        def self.marker
          MARKER
        end  

        MARKER_SHADOW = FindIt::Feature::MapMarker.new(
          "/mapicons/vote_icon_shadow.png",        
          :height => 32, :width => 59).freeze            
        
        def self.marker_shadow
          MARKER_SHADOW
        end 
        

        DATAFILE = File.dirname(__FILE__) + "/data/Voting_Places.csv"
          
        def self.load_dataset
          
          ds = {}
            
          CSV.foreach(DATAFILE, :headers => true) do |row|
            
            #
            # Example Row:
            #
            #  <CSV::Row
            #    "precinct":"360"
            #    "name":"Bowie High School"
            #    "street":"4103 West Slaughter Ln"
            #    "city":"Austin"
            #    "state":"TX"
            #    "geo_longitude":"-97.8573487400007"
            #    "geo_latitude":"30.1889148140537"
            #    "geo_accuracy":"house"
            #    "notes":nil>
            #
            
            lng = row["geo_longitude"].to_f
            lat = row["geo_latitude"].to_f
            pct = row["precinct"].to_i  
            note = "precinct #{pct}"
            note += " - #{row["notes"]}" if row["notes"]
            
            ds[pct] = {       
              :name =>  row["name"],
              :street => row["street"],
              :city => row["city"],
              :state => row["state"],
              :note => note,
              :location => Location.new(lat, lng, :DEG),
            }.freeze
           
          end
          
          return ds
        end
        
        DATASET = load_dataset.freeze         

                
        def self.closest(origin)

          sth = DB.execute(%q{SELECT * FROM travis_co_tx_us_voting_districts
            WHERE ST_Contains(the_geom, ST_Transform(ST_SetSRID(ST_Point(?, ?), 4326), 3081))},
            origin.lng, origin.lat)
          ds = sth.fetch_all
          sth.finish          
      
          case ds.count
          when 0
            return nil
          when 1
            rec = ds.first
          else
            raise "overlapping precincts at location lat=#{lat}, lng=#{lng}"
          end
          
          precinct = rec[:p_vtd].to_i
          rec = DATASET[precinct]          
          raise "cannot find voting place for precinct #{precinct}" unless rec                  

          new(rec[:location],
            :title => "Your voting place",
            :name => rec[:name],
            :address => rec[:street],
            :city => rec[:city],
            :state => rec[:state],
            :note => rec[:note],
            :origin => origin
          )
        end        

      end
    end
  end
end