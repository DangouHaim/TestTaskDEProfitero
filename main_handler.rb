# Processing all results from main here
class MainHandler
    include DAL

    # Receive events from main

    def on_data_handler(sender, args)
        CsvStorage.new.save(args, "results.csv")
    end

end