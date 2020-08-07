load 'dal/readonly_network_repository.rb'
load 'dal/context.rb'

require 'net/http'
require 'digest/sha1'
require 'nokogiri'

module DAL

    # source - target site url
    # context - category page with target pages inside
    # pages - array of pages url parsed by context
    # cached - (bool) use or not to use method call caching
    
    class NetworkRepository

        # To implement interface
        include ReadOnlyNetworkRepository
        
        # Context for collecting urls (for all() and any?() methods)
        attr_reader :context, :cached, :source, :pages

        private
        attr_writer :cached, :source, :pages
        
        @cache = nil

        def initialize(source_uri, cached = false)
            puts ">> #{self.class} : #{__method__}"

            self.cached = cached
            self.source = source_uri.to_s()

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
                hash = Digest::SHA1.hexdigest(self.source + self.context.to_s())
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
                    hash = Digest::SHA1.hexdigest(uri + conditions.sort().to_s())
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

        def any?()
            puts ">> #{self.class} : #{__method__}"
            puts "<< #{self.class} : #{__method__}"
            return !self.pages.empty?()
        end

        def all()
            puts ">> #{self.class} : #{__method__}"
            puts "<< #{self.class} : #{__method__}"
            return self.pages
        end
        # Interface part end

        private

        # Parsing pages relative urls from base url
        def prepare_pages_from_source(source, context)
            raise( "Invalid context" ) if !context.is_a?(Context)

            uri = uri.to_s

            uri = URI::join(source.to_s(), context.context.to_s).to_s if !uri.include?(source)
            uri = URI.parse(uri)
            
            html = Net::HTTP.get(uri)

            document = Nokogiri::HTML(html)

            results = []

            for item in document.xpath(context.condition)
                results << item.value
            end
            
            return results
        end

        # Get parsed page data by url or relative url
        def get_page(uri, conditions)
            uri = uri.to_s()
            
            uri = URI::join(self.source, uri).to_s if !uri.include?(self.source)
            uri = URI.parse(uri)

            html = Net::HTTP.get(uri)

            if self.cached
                # Caching html parsing to not repeat same operations
                # with same html
                hash = Digest::SHA1.hexdigest(html + conditions.sort().to_s())
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