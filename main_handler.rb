# Processing all results from main here
class MainHandler
    include DAL

    # Receive events from main

    def on_data_handler(sender, args)
        p args
        CsvStorage.new.save(args, "results.csv")
    end

end