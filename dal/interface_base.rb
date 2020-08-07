# Basic interface behaviour
module DAL
    module InterfaceBase
        
        # To not override or access from the outside, excluding inheritance
        private
        protected
        def not_implemented()
            raise("Not implemented")
        end

    end
end