# frozen_string_literal: true

require 'open-uri'
require 'json'
require_relative "meal.rb"
require_relative "api_interface.rb"

module MealSelector
  class MealSelector
    def initialize(load)
      raise "Invalid load value, should be true or false" if !!load != load
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

    def menu()
      quit = false
      input_phase = true
      while !quit
        clear()
        puts "Thank you for choosing Meal Selector."
        puts "Please select a number from the options below:"
        puts "`1` Search for meal by name"
        puts "`2` Show meals by a category"
        puts "`3` Show meals by a main ingrediant"
        puts "`4` Show me a random meal"
        #TODO puts "5. View favorite meals"
        puts '`0` Exit program'
        input_phase = true
        while !quit && input_phase
          input = begin
            Integer(gets.chomp)
          rescue ArgumentError
            -1
          end
          case input
          when 1
            search_meal_by_name()
            input_phase = false
          when 2
            raise get_meals_by_categories()
            input_phase = false
          when 3
            get_meals_by_main_ingrediant()
            input_phase = false
          when 4
            # Showing Random meal
            list_meals(@interface.random_meal)
            input_phase = false
          when 5
            raise NotImplementedError("View favorite not implimented")
            input_phase = false
          when 0
            input_phase = false
            quit = true
          else
            puts "Invalid selection, please try again"
          end
        end
      end
    end

    private

    def search_meal_by_name
      puts "Search for meal by name"
      sleep 1
    end

    def get_meals_by_categories
      puts "Show meals by a category"
      sleep 1
    end

    def get_meals_by_main_ingrediant
      puts "Show me a random meal"
      sleep 1
    end

    def get_random_meal()

    end

    def list_meals(meal_arr)
      # List meals to front end for selection
      # If arry only has one meal it will directly show that meal.
      raise "meals is not an array, instead it is #{meal_arr.class}" unless meal_arr.is_a?(Array)
      raise 'meals is empry' if meal_arr.empty?

      if meal_arr.count == 1
        show_meal(meal_arr[0])
      else
        puts "show list of meal"
      end
    end

    def show_meal(meal)
      raise "meal is not a MealSelector::Meal instead #{meal.class}" unless meal.is_a?(Meal)
      raise "meal is not frozen" unless meal.frozen?
      clear()
      puts "Name: #{meal.name.capitalize}"
      puts "Category: #{meal.category.capitalize}"
      puts "Type: #{meal.type.capitalize}"
      puts 'Ingredient:'
      meal.ingredient.each do
        |item, amount|
        puts "=> #{item}: #{amount}"
      end
      puts 'Instructions:'
      puts "#{meal.instructions}"
      puts ''

      puts "Go back press enter"
      gets.chomp!
      # TODO: add meal to favorite

    end



    def clear()
      # Marks old Input and clears screen
      puts "=== old console Output ==="
      puts `clear`
    end
  end
end
