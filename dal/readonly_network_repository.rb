load 'dal/interface_base.rb'

# Like interface
module DAL

    module ReadOnlyNetworkRepository

        # Use interface basics
        include InterfaceBase

        # uri - url as string
        # conditions - array ( [] )
        # Returns array of arrays ( [ [] ] ) for each condition
        def get(uri, conditions)
            not_implemented()
        end

        # Returns array ( [] ) of all relatie page urls
        def all()
            not_implemented()
        end

        # Checks if any relative page urls is exists
        def any?()
            not_implemented()    
        end

    end

end