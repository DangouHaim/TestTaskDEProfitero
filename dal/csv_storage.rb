load 'dal/storage.rb'

require 'csv'

module DAL

    class CsvStorage

        # To implement interface
        include Storage

        def save(data, file)
            puts ">> #{self.class} : #{__method__}"

            begin
                file = file.to_s()
                data = data.to_a()
    
                CSV.open(file, "w") do |w|
                    data.each() do |line|
                        w << line
                    end
                end 
            rescue => exception
                p exception
            ensure
                puts "<< #{self.class} : #{__method__}"    
            end
        end

        def load(file)
            puts ">> #{self.class} : #{__method__}"

            begin
                file = file.to_s()

                return CSV.open(file, "r")
            rescue => exception
                p exception
            ensure
                puts "<< #{self.class} : #{__method__}"
            end
        end
        
    end

end