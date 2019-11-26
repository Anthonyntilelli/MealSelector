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
        puts "Thank you for using Meal Selector."
        puts "Please select a number from the options below:"
        puts "`1` Search for meal by name (not Implimented)"
        puts "`2` Show meals by a category"
        puts "`3` Show meals by a main ingrediant (not Implimented)"
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
            get_meals_by_categories()
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
      choice = nil
      clear()
      puts "Select a meal category:"
      Meal.categories.each_index do |index| 
        puts "=> `#{index+1}` #{Meal.categories[index]}"
      end
      puts '=> `0` Return to menu'

      while !choice
        choice = begin
          Integer(gets.chomp)
        rescue ArgumentError
          -1
        end
        
        if choice == 0
          puts "Exiting"
        elsif choice.between?(1,Meal.categories.size)
          puts "Searching for #{Meal.categories[choice-1]} meals"
          list_meals(@interface.meals_by_category(Meal.categories[choice-1]))
        else
          choice = nil
          puts "Invalid input, please try again"
        end
      end
      puts "Press enter to return to menu" if choice != 0 # development
      gets.chomp if choice != 0  # development
    end

    def get_meals_by_main_ingrediant
      puts "Show meal by main ingrediant"
      sleep 1
    end

    def list_meals(meal_arr)
      # List meals to front end for selection
      # If arry only has one meal it will directly show that meal.
      raise "meals is not an array, instead it is #{meal_arr.class}" unless meal_arr.is_a?(Array)
      raise 'meals is empry' if meal_arr.empty?

      if meal_arr.count == 1
        show_meal(meal_arr[0])
      else
        start = 0
        end_index = meal_arr.count <= 10 ? meal_arr.size - 1 : 10
        puts 'Select Meal'
        meal_arr.each do |meal|
          puts "=> #{meal.name}: #{meal.type}"
        end
        puts "show list of meal (#{meal_arr.size})"
        sleep 5
      end
    end

    def show_meal(meal)
      # Shows a meal
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
