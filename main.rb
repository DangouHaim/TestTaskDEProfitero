load 'dal/network_repository.rb'
load 'dal/csv_storage.rb'
load 'dal/event.rb'
load 'main_handler.rb'

require 'rubygems'
require 'thread/pool'
require 'concurrent'

class Main
    include DAL

    attr_reader :on_data_ready
    
    private
    attr_writer :on_data_ready

    @repository
    @pool

    def initialize
        puts ">> #{self.class} : #{__method__}"

        # Prepare event
        self.on_data_ready = Event.new

        source = 'http://arcosplus.by/'

        @repository = NetworkRepository.new(source, true)

        call = Proc.new { init() }

        p "Init elapsed time : " + elapsed(call)[0].to_s()

        puts "<< #{self.class} : #{__method__}"
    end

    def init()
        puts ">> #{self.class} : #{__method__}"

        categoryPage = "/katalog-kofe/?dataType=Vergnano"
        pageButton = '//div[@class="post"]//a[@class="button"]/@href'
        core_count = 8

        context = Context.new(categoryPage, pageButton)
            
        
        @repository.context = context

        puts "<< #{self.class} : #{__method__}"
    end

    public
    def parse()
        puts ">> #{self.class} : #{__method__}"

        # Thread safe array
        elapsed_times = Concurrent::Array.new
        results = Concurrent::Array.new

        # Using thread pool to optimize accessing to threads
        @pool = Thread.pool(8)

        if(@repository.any?())
            @repository.all().each() do |page|

                @pool.process do
                    call = Proc.new do
                        @repository.get(page, [ "//div[@class='content']/h3", "//div[@class='content']/p" ])
                    end
    
                    res = elapsed(call)
    
                    puts 'Get elapsed time : ' + res[0].to_s()
                    elapsed_times << res[0].to_s()
                    
                    result = []
                    
                    result << res[1][0][0].children.text.strip()
                    result << res[1][1][0].children.text.strip()
                    result << res[0].to_s()
    
                    results << result
                end

            end
        end

        @pool.shutdown()

        self.on_data_ready.invoke(self, results)

        puts "<< #{self.class} : #{__method__}"
    end
end

def elapsed(method)
    time = Time.now()

    result = method.call()

    return [ Time.now() - time, result ]
end

def main()
    main = Main.new
    handler = MainHandler.new

    # Bind event handlers
    main.on_data_ready.bind(handler.method(:on_data_handler))

    # Process data
    call = Proc.new { main.parse() }

    elapsed = []

    elapsed << "Parse elapsed time: " + elapsed(call)[0].to_s()
    # Call this twice to show optimized cached call
    elapsed << "Parse elapsed time: " + elapsed(call)[0].to_s()

    elapsed.each &(-> (s) { p s })
end

call = Proc.new { main() }

puts "Total elapsed time: " + elapsed(call)[0].to_s()