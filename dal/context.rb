module DAL
    class Context
        
        attr_reader :context, :condition

        private
        attr_writer :context, :condition

        def initialize(context, condition)
            self.context = context
            self.condition = condition
        end

    end
end