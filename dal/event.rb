module DAL
    # Use Object.method(:meth_name) to bind event handlers
    # Use next signature for handler methods: method(sender, args)
    class Event

        attr_accessor :handlers

        protected :handlers

        def initialize()
            self.handlers = []
        end
        
        def bind(handler)
            self.handlers << check_handler(handler)
        end

        def unbind(handler)
            self.handlers.remove(check_handler(handler))
        end

        def invoke(sender, args)
            self.handlers.each &(-> (s) { s.call(sender, args) })
        end

        private
        def check_handler(handler)
            if !handler.is_a?(Method)
                raise "Handler must be a Method"
            end

            return handler
        end
    end
end