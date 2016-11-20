module Muscat
  #The maintenance class bundles relevant methods and actions for changing RISM data in Muscat application.
  #It contains
  # * Logging
  # * Progressbar
  class Maintenance
    attr_accessor :collection, :host, :logger, :bar, :filename
    # Creates a new maintenance object with logging and progressbar
    # Required parameter: collection of records
    def initialize(collection)
      @filename = File.basename($0, '.rb')
      @host = Socket.gethostname
      @logger = Logger.new("#{File.dirname($0)}/log/#{@filename}.log")
      @collection = collection
      @bar = ProgressBar.new(collection.size)
    end

    # Starts execution of maintenance
    # Required parameter: lambda or proc defining change routine
    def execute process
      raise 'Process not defined' unless process
      logger.info("#{host}: Size of collection --> #{collection.size}")
      collection.each do |e|
        process.call(e)
        bar.increment!
      end
    end
  end
end
