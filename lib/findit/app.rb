require 'findit'
require 'rdbi-driver-sqlite3'

# Include all of the local features that we want to support.
require 'findit/feature/austin.ci.tx.us/fire-station'
#require 'findit/feature/austin.ci.tx.us/facility'
require 'findit/feature/austin.ci.tx.us/historical'
require 'findit/feature/austin.ci.tx.us/police-station'
require 'findit/feature/austin.ci.tx.us/apd-incident'
#require 'findit/feature/travis.co.tx.us/voting-place'


module FindIt

  #
  # Implementation of the FindIt application.
  #
  # Example usage:
  #
  #    require "findit/app"
  #    findit = FindIt::App.new
  #    features = findit.nearby(latitude, longitude))
  #
  class App
  
    # DBI URI for the FindIt database.
    #
    # Default value used when constructing a new FindIt::App instance.
    #
    DB_URI = 'DBI:SQLite3:cycle_nearby.db'

    # Features further than this distance (in miles) away from
    # the current location will be filtered out of results.
    #
    # Default value used when constructing a new FindIt::App instance.
    #
    MAX_DISTANCE = 20

    # Construct a new FindIt app instance.
    #
    # Options:
    # * :db_uri - DBI URI for the FindIt database. (default: DB_URI)
    # * :db_user - Username credential to access the FindIt database.
    #   (default: DB_USER)
    # * :db_password - Password credential to access the FindIt database.
    #   (default: DB_PASSWORD)
    # * :max_distance -  Features further than this distance (in miles)
    #   away from the current location will be filtered out of results.
    #   (default: MAX_DISTANCE)
    #    
    def initialize(options = {})
      @db_uri = options[:db_uri] || DB_URI
      @db_user = options[:db_user] || DB_USER
      @db_password = options[:db_password] || DB_PASSWORD
      @max_distance = options[:max_distance] || MAX_DISTANCE
      
      # RDBI connection to SQLite3 "cycle_nearby" database.
      @db = nil	# force scope
      begin
        @db = RDBI.connect(:SQLite3, :database => 'cycle_nearby.db')
        @db.handle.enable_load_extension(true)
        @db.handle.load_extension('/usr/lib64/libspatialite.so')
      rescue
        STDERR.puts "FATAL ERROR: unable to connect to database - #{$!}."
        exit
      end

      # List of classes that implement features (derived from FindIt::BaseFeature).
      @feature_classes = [
#        FindIt::Feature::Austin_CI_TX_US::FacilityFactory.create(@db, :POST_OFFICE),
#        FindIt::Feature::Austin_CI_TX_US::FacilityFactory.create(@db, :LIBRARY),
        FindIt::Feature::Austin_CI_TX_US::HistoricalFactory.create(@db, :MOON_TOWER),
        FindIt::Feature::Austin_CI_TX_US::FireStation, 
        FindIt::Feature::Austin_CI_TX_US::PoliceStation,
#        FindIt::Feature::Travis_CO_TX_US::VotingPlaceFactory.create(@db, "20120731"),
	FindIt::Feature::Austin_CI_TX_US::IncidentFactory.create(@db, 'THEFT OF BICYCLE'),
      ]  
      
    end
    
    
    # Search for features near a given location.
    #
    # Parameters:
    #
    # * lat -- the latitude (degrees) of the location, as a Float.
    #
    # * lng -- the longitude (degrees) of the location, as a Float.
    #
    # Returns: A list of FindIt::BaseFeature instances.
    #
    def nearby(lat, lng)
      origin = FindIt::Location.new(lat, lng, :DEG) 
      
      @feature_classes.map do |klass|
        # For each class, run the "closest" method to find the
        # closest feature of its type.
        klass.send(:closest, origin)
      end.reject do |feature|
        # Reject results that came back nil or are too far away.
        feature.nil? || feature.distance > MAX_DISTANCE
      end
    end
 
  end # module App
end # module FindIt
