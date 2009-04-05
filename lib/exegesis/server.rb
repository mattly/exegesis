module Exegesis
  class Server
    include Exegesis::Http
    
    attr_accessor :uri, :version

    # Creates a new instance of Exegesis::Server. Defaults to http://localhost:5984 and
    # verifies the existance of the database.
    def initialize address='http://localhost:5984'
      @uri = address
      @version = get(@uri)['version']
    end
    
    # returns an array of all the databases on the server
    def databases
      get "#{@uri}/_all_dbs"
    end
    
    # creates a database with the given name on the server
    def create_database name
      put "#{@uri}/#{name}"
    end
    
    def inspect
      "#<Exegesis::Server #{@uri}>"
    end
  end
end