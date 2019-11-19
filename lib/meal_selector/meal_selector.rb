
require 'open-uri'
require 'json'
require_relative "meal.rb"
require_relative "api_interface.rb"
require_relative "frontend.rb"

module MealSelector
  class MealSelector
    def initialize(load)
      @interface = nil
      if load
        begin
          @interface = ApiInterface.load()
          @interface.populate_categories()
        rescue
          abort("Failure Loading file")
        end
      else
        until @interface
          puts "To start using meal selector, please input below info:"
          print 'API KEY ("QQ" will kill the program): '
          key = gets.chomp
          exit if key == 'QQ'
          print "Version: "
          version = gets.chomp
          begin
            @interface = ApiInterface.new(key,version.to_i)
            @interface.populate_categories()
          rescue
            puts "Error when setting up key and version, try again."
            key = nil
            version = nil
            @interface = nil
          end
        end
        answer = nil
        until answer
          print "Save API Key and Version [Y/N]? "
          answer = gets.strip
          if answer != "N" && answer != "Y"
            puts "Invalid input, try again (#{answer})"
            answer = nil
          end
        end
          @interface.save() if answer == "Y"
        end
    end

    def start()
    end
  end
end
