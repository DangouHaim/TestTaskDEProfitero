load 'dal/readonly_network_repository.rb'
load 'dal/context.rb'

require 'net/http'
require 'digest/sha1'
require 'nokogiri'
require 'curb'

module DAL

    # source - target site url
    # context - category page with target pages inside
    # pages - array of pages url parsed by context
    # cached - (bool) use or not to use method call caching
    
    class NetworkRepository

        # To implement interface
        include ReadOnlyNetworkRepository
        
        # Context for collecting urls (for all and any? methods)
        attr_reader :context, :cached, :source, :pages, :use_curl

        private
        attr_writer :cached, :source, :pages, :use_curl
        
        @cache = nil

        def initialize(source_uri, cached = false, use_curl = true)
            puts ">> #{self.class} : #{__method__}"

            self.use_curl = use_curl
            self.cached = cached
            self.source = source_uri.to_s

            # Method caching
            if self.cached
                @cache = Concurrent::Hash.new
            end

            puts "<< #{self.class} : #{__method__}"
        end

        public

        def context=(context)
            @context = context
            
            if(self.cached)
                # Caching html parsing to not repeat same operations
                # with same html
                hash = Digest::SHA1.hexdigest(self.source + self.context.to_s)
                self.pages = @cache[hash] ||= prepare_pages_from_source(self.source, self.context)
            else
                self.pages = prepare_pages_from_source(self.source, self.context)
            end
        end

        # Interface part
        def get(uri, conditions)
            puts ">> #{self.class} : #{__method__} (#{uri}, #{conditions})"

            begin

                if self.cached
                    # Caching html parsing to not repeat same operations
                    hash = Digest::SHA1.hexdigest(uri + conditions.sort.to_s)
                    return @cache[hash] ||= get_page(uri, conditions)
                else
                    return get_page(uri, conditions)
                end

            rescue => exception
                p exception
            ensure
                puts "<< #{self.class} : #{__method__}"
            end
        end

        def any?
            puts ">> #{self.class} : #{__method__}"
            puts "<< #{self.class} : #{__method__}"
            return !self.pages.empty?
        end

        def all
            puts ">> #{self.class} : #{__method__}"
            puts "<< #{self.class} : #{__method__}"
            return self.pages
        end
        # Interface part end

        private

        def get_html(uri)
            if(self.use_curl)
                html = Curl.get(uri).body_str
            else
                html = Net::HTTP.get(uri)
            end
        end

        def add_param(url, param_name, param_value)
            uri = URI(url)
            params = URI.decode_www_form(uri.query || "") << [param_name, param_value]
            uri.query = URI.encode_www_form(params)
            uri
          end

        # Parsing pages relative urls from base url
        def prepare_pages_from_source(source, context)
            raise( "Invalid context" ) if !context.is_a?(Context)
            raise( 'Context can not to contain source uri: ' + source ) if context.context.to_s.include?(source)

            uri = uri.to_s

            uri = URI::join(source.to_s, context.context.to_s)
            
            html = get_html(uri)

            document = Nokogiri::HTML(html)

            results = []

            for item in document.xpath(context.condition)
                results << item.value
            end
            
            if context.pagination
                page = 2

                pagination = true

                while pagination
                    pquery = add_param(uri.to_s, context.pagination, page.to_s)
                    
                    puts "Pagination request to " + pquery.to_s

                    html = get_html(pquery)
                    document = Nokogiri::HTML(html)
                    
                    paged = document.xpath(context.condition)
                    
                    if !paged.last
                        pagination = false
                        puts 'Pages readed: ' + (page - 1).to_s
                        puts 'Total product pages: ' + results.size.to_s
                        break
                    end
                    
                    for item in paged
                        results << item.value
                    end

                    page += 1

                end

            end


            return results
        end

        # Get parsed page data by url or relative url
        def get_page(uri, conditions, use_curl = true)
            uri = uri.to_s
            
            uri = URI::join(self.source, uri) if !uri.include?(self.source)

            html = get_html(uri)

            if self.cached
                # Caching html parsing to not repeat same operations
                # with same html
                hash = Digest::SHA1.hexdigest(html + conditions.sort.to_s)
                return @cache[hash] ||= parse_html(html, conditions)
            else
                return parse_html(html, conditions)
            end
        end

        # Apply xPath to html to get required data
        def parse_html(html, conditions)
            document = Nokogiri::HTML(html)
            result = []
            
            for c in conditions
                temp = []
                for item in document.xpath(c)
                    temp << item
                end
                result << temp
            end
            
            return result
        end
        
    end

end