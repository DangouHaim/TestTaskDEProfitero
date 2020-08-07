module DAL
    class Context
        
        attr_reader :context, :condition, :pagination

        private
        attr_writer :context, :condition, :pagination

        def initialize(context, condition, pagination = nil)
            self.context = context
            self.condition = condition
            self.pagination = pagination
        end

    end
end