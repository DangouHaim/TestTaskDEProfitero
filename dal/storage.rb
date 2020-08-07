load 'dal/interface_base.rb'

# Like interface
module DAL
    module Storage

        # Use interface basics
        include InterfaceBase

        def save(data, file)
            not_implemented()
        end

        def load(file)
            not_implemented()
        end

    end
end