module Muscat
  class Maintenance
    attr_accessor :collection, :host, :logger, :bar, :filename
    def initialize(collection)
      @filename = File.basename($0, '.rb')
      @host = Socket.gethostname
      @logger = Logger.new("#{File.dirname($0)}/log/#{@filename}.log")
      @collection = collection
      @bar = ProgressBar.new(collection.size)
    end

    def execute process
      raise 'Process not defined' unless process
      logger.info("#{host}: Size of collection --> #{collection.size}")
      collection.each do |e|
        process.call(e)
        logger.info("#{host}: #{e.id} updated.")
        bar.increment!
      end
    end
  end
end
