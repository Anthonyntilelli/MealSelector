# frozen_string_literal: true

require 'open-uri'
require 'json'
require_relative "meal.rb"
require_relative "api_interface.rb"
require_relative "meal_list.rb"

module MealSelector
  class MealSelector
    def initialize
      # Trys to load key from file and ask if file does not exist/bad format
      begin
        @interface = ApiInterface.load()
        @interface.populate_categories()
        loaded_by_file = true
      rescue
        @interface = nil
      end

      # => No key file found
      until @interface
        puts "To start using meal selector, please input below info:"
        print 'API KEY ("QQ" will kill the program): '
        key = gets.chomp
        exit if key == 'QQ'
        print "Version: "
        version = gets.chomp
        exit if version == 'QQ'
        begin
          @interface = ApiInterface.new(key,version)
          @interface.populate_categories()
          loaded_by_file = false
        rescue
          puts "Error when setting up key and version, try again."
          key = nil
          version = nil
          @interface = nil
        end
      end
      answer = nil
      if !loaded_by_file
        until answer
          print "Save API Key and Version [Y/N]? "
          answer = gets.strip.upcase
          if answer != "N" && answer != "Y"
            puts "Invalid input, try again (#{answer})"
            answer = nil
          end
        end
        @interface.save() if answer == "Y"
      end
      # => No key file found

      Meal.load_favorites()
      Meal.favorites_init
    end

    def menu()
      quit = false
      input_phase = true
      while !quit
        clear()
        puts "Thank you for using Meal Selector."
        puts "Please select a number from the options below:"
        puts "`1` Search for meal by name"
        puts "`2` Show meals by a category"
        puts "`3` Show meals by a main ingrediant"
        puts "`4` Show me a random meal"
        puts "`5` View favorite meals" if !Meal.favorites.empty?
        puts "`6` Clear all favorite meals" if !Meal.favorites.empty?
        puts '`0` Exit program' if !Meal.favorites_changed?
        puts '`0` Exit program (don`t save favorite change)' if Meal.favorites_changed?
        puts '`-1` Exit program  and save favorites' if Meal.favorites_changed?

        input_phase = true
        while !quit && input_phase
          input = user_input_int(-1,6)
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
            show_meal(@interface.random_meal)
            input_phase = false
          when 5
            if !Meal.favorites.empty?
              show_meal_list(Meal.favorites)
            else
              puts "No Favorites to view"
              sleep 0.75
            end
            input_phase = false
          when 6
            if !Meal.favorites.empty?
              print "Are you sure?[y/n]: "
              user_confirmation = gets.chomp.downcase
              if user_confirmation == "y"
                puts "Clearing favorites"
                Meal.favorites.clear
              elsif user_confirmation == "n"
                puts "aborting clear"
              else
                puts "unknown input, assuming no"
              end
            else
              puts "Favorites are already cleared"
            end
            sleep 1
            input_phase = false
          when 0
            puts "Quiting"
            input_phase = false
            quit = true
          when -1
            if Meal.favorites_changed?
              puts "Saving favorite changes"
              Meal.save_favorite
              input_phase = false
              quit = true
            else
              puts "No changes to favorites to save"
            end
          else
            puts "Invalid selection, please try again"
          end
        end
      end
    end

    private

    def search_meal_by_name
      # Search for meal by entered name
      clear()
      searching = true
      puts "Enter a meal name to search:"
      puts "Enter `0` to return to menu"
      while searching
        print "$: "
        user_input = gets.chomp
        if user_input == '0'
          searching = false
        else
          results = @interface.search_meal_name(user_input)
          if results.nil?
            puts "Cannot find any meals by that name, try Again"
          else
            searching = false
            show_meal_list(results)
          end
        end
      end
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
        print "$: "
        choice = begin
          Integer(gets.chomp)
        rescue ArgumentError
          -1
        end

        if choice == 0
          puts "Exiting"
        elsif choice.between?(1,Meal.categories.size)
          puts "Searching for #{Meal.categories[choice-1]} meals"
          show_meal_list(@interface.meals_by_category(Meal.categories[choice-1]))
        else
          choice = nil
          puts "Invalid input, please try again"
        end
      end
    end

    def get_meals_by_main_ingrediant
      # Search for meal by main ingrediant
      clear()
      searching = true
      puts "Enter an ingrediant to search by:"
      puts "Enter `0` to return to menu"
      while searching
        print "$: "
        user_input = gets.chomp
        if user_input == '0'
          searching = false
        else
          results = @interface.search_by_ingredient(user_input)
          if results.nil?
            puts "Cannot find any meals for that ingredient, try Again"
          else
            searching = false
            show_meal_list(results)
          end
        end
      end
    end

    def show_meal_list(meals)
      # List meals
      raise 'meals is empty' if meals.empty?
      raise "Meals does not respond to `[]`" unless meals.respond_to?("[]")

      count = 0
      round = {} # record the keys per round {round => id }
      clear()
      puts "Select a meal below:"
      meals.collect do |key, value|
        count += 1
        round[count] = key
        # raise "Name not defined for key: #{key}"
        if meals.respond_to?("partial?")
          # Partial meal => value is name
          puts "`#{count}` #{value}"
        else
          # Meal
          puts "`#{count}` #{value.name}"
        end
      end
      puts '`0` Return to menu'

      input = nil
      while !input
        print "$: "
        input = begin
          Integer(gets.chomp)
        rescue ArgumentError
          false
        end
        return if input == 0
        if !input || round[input].nil? || input.negative?
          puts "Invalid input, try again"
          input = false
        end
      end
      if meals.respond_to?("partial?")
        # Partial meal => resolve id to get full meal
        meal_object = @interface.meal_by_id(round[input].to_i)
      else
        # Meal
        meal_object = meals[round[input]]
      end
      raise "Meal not found by id #{id}" if meal_object.nil?
      show_meal(meal_object)
    end

    def show_meal(meal)
      # Shows a meal
      raise "meal is not a MealSelector::Meal instead #{meal.class}" unless meal.is_a?(Meal)
      raise "meal is not frozen" unless meal.frozen?

      clear()
      id = meal.id
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

      puts "Enter `F` to add to favorites and go back" if Meal.favorites[id].nil?
      puts "Enter `R` to remove from favorites" if !Meal.favorites[id].nil?
      puts "Press `enter` to go back (no change to favorite)"
      print "$: "
      user_input = gets.chomp!.upcase
      case user_input
      when "F"
        if Meal.favorites[id].nil?
          puts "Adding to favorites"
          meal.add_to_favorites
        else
          puts "Meal already in favorites, skipping"
        end
      when "R"
        if !Meal.favorites[id].nil?
          puts "Removing Favorite"
          Meal.favorites.delete(id)
        else
          puts "Meal not in favorites, skipping"
          sleep 0.75
        end
      when ""
        puts "Going Back"
      else
        puts "Unknown Input, going back"
      end
    end

    def clear
      # Marks old Input and clears screen
      puts "=== old console Output ==="
      puts `clear`
    end

    def user_input_int(range_start,range_end)
      user_input = "INVALID"
      while user_input == "INVALID"
        print "$: "
        begin
          input = Integer(gets.chomp)
          raise ArgumentError.new("Not in range") unless input.between?(range_start,range_end)
          user_input = input
        rescue ArgumentError
          user_input = "INVALID"
          puts "Invalid Input, please try again  (#{range_start} <=> #{range_end})"
        end
      end
      user_input
    end

  end
end
