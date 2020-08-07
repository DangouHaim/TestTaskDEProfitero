load 'dal/network_repository.rb'
load 'dal/csv_storage.rb'
load 'dal/event.rb'
load 'main_handler.rb'

require 'rubygems'
require 'thread/pool'
require 'concurrent'
require 'pry'

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

        source = 'https://www.petsonic.com/snacks-huesos-para-perros/'

        @repository = NetworkRepository.new(source, true)

        call = Proc.new { init() }

        p 'Init elapsed time : ' + elapsed(call)[0].to_s()

        puts "<< #{self.class} : #{__method__}"
    end

    def init()
        puts ">> #{self.class} : #{__method__}"

        categoryPage = ''
        pageButton = '//div[@class="pro_outer_box"]/div[contains(@class, "product-desc")]/a[1]/@href'
        pagination = "p"

        context = Context.new(categoryPage, pageButton, pagination)
        
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
                        @repository.get(page, [ '//h1[@class="product_main_name"]',
                        '//label[contains(@class, "label_comb_price")]',
                        '//img[@id="bigpic"]/@src'
                     ])
                    end
    
                    res = elapsed(call)
    
                    puts 'Get elapsed time : ' + res[0].to_s()
                    elapsed_times << res[0].to_s()

                    # Get product title
                    product = res[1][0][0].children.text.strip()

                    # Get product photo
                    image = res[1][2][0].children.text.strip()

                    res[1][1].each_with_index() do |item, i|

                        result = []

                        # Get variation title
                        title = item.xpath('//span[@class="radio_label"]').children[i].text.strip()
                        # Get variation price
                        price = item.xpath('//span[@class="price_comb"]').children[i].text.strip()

                        result << product + " - " + title
                        result << price
                        result << image

                        results << result

                    end
                    
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

    elapsed = "Parse elapsed time: " + elapsed(call)[0].to_s()

    p elapsed
end

call = Proc.new { main() }

puts "Total elapsed time: " + elapsed(call)[0].to_s()