load 'dal/network_repository.rb'
load 'dal/event.rb'
load 'main_handler.rb'

require 'rubygems'
require 'thread/pool'
require 'concurrent'
require 'optparse'
require 'pry'

class Main
    include DAL

    attr_reader :on_data_ready, :source, :category, :csv_file
    
    private
    attr_writer :on_data_ready, :source, :category, :csv_file

    @repository
    @pool

    def initialize(source, category, csv_file)
        puts ">> #{self.class} : #{__method__}"

        # Prepare event
        self.on_data_ready = Event.new

        self.source = source
        self.category = category
        self.csv_file = csv_file

        @repository = NetworkRepository.new(self.source, false)

        call = Proc.new { init }

        p 'Init elapsed time : ' + elapsed(call)[0].to_s

        puts "<< #{self.class} : #{__method__}"
    end

    def init
        puts ">> #{self.class} : #{__method__}"

        categoryPage = self.category
        pageButton = '//div[@class="pro_outer_box"]/div[contains(@class, "product-desc")]/a[1]/@href'
        pagination = "p"

        context = Context.new(categoryPage, pageButton, pagination)
        
        @repository.context = context

        puts "<< #{self.class} : #{__method__}"
    end

    public
    def parse
        puts ">> #{self.class} : #{__method__}"

        # Thread safe array
        elapsed_times = Concurrent::Array.new
        results = Concurrent::Array.new

        # Using thread pool to optimize accessing to threads
        @pool = Thread.pool(8)
        
        if(@repository.any?)
            @repository.all.each do |page|

                @pool.process do
                    call = Proc.new do
                        @repository.get(page, [ '//h1[@class="product_main_name"]',
                        '//label[contains(@class, "label_comb_price")]',
                        '//img[@id="bigpic"]/@src'
                     ])
                    end
    
                    res = elapsed(call)
    
                    puts 'Get elapsed time : ' + res[0].to_s
                    elapsed_times << res[0].to_s

                    # Get product title
                    product = res[1][0][0].children.text.strip

                    # Get product photo
                    image = res[1][2][0].children.text.strip
                    
                    # Preparing image id
                    image_id = image.gsub(/[^0-9]/, '')
                    image_id = image_id.to_i
                    image_origin_id = image_id

                    res[1][1].each_with_index do |item, i|

                        result = []

                        image_id += i

                        # Get variation title
                        title = item.xpath('//span[@class="radio_label"]').children[i].text.strip
                        # Get variation price
                        price = item.xpath('//span[@class="price_comb"]').children[i].text.strip

                        result << product + " - " + title
                        result << price
                        result << image.sub(image_origin_id.to_s, image_id.to_s)

                        results << result

                    end
                    
                end

            end
        end

        @pool.shutdown

        self.on_data_ready.invoke(self, [ self.csv_file, results, @repository.pages_processed ])

        puts "<< #{self.class} : #{__method__}"
    end
end

def elapsed(method)
    time = Time.now

    result = method.call

    return [ Time.now - time, result ]
end

def main

    # Parse args
    options = {}
    OptionParser.new do |opt|
        opt.on('--u URI') { |o| options[:uri] = o }
        opt.on('--c CATEGORY') { |o| options[:category] = o }
        opt.on('--o CSV') { |o| options[:csv] = o }
    end.parse!

    # Debug default values
    if !options[:uri]
        options[:uri] = 'https://www.petsonic.com/snacks-huesos-para-perros/'
    end

    if !options[:csv]
        options[:csv] = 'results'
    end

    main = Main.new(options[:uri], options[:category], options[:csv])

    handler = MainHandler.new

    # Bind event handlers
    main.on_data_ready.bind(handler.method(:on_data_handler))

    # Process data
    call = Proc.new { main.parse }

    elapsed = "===  Total parsing elapsed time: " + elapsed(call)[0].to_s

    puts elapsed
end

call = Proc.new { main }

puts "===  Total elapsed time: " + elapsed(call)[0].to_s