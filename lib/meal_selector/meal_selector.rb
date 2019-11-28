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
          exit if version == 'QQ'
          begin
            @interface = ApiInterface.new(key,version)
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
          answer = gets.strip.upcase
          if answer != "N" && answer != "Y"
            puts "Invalid input, try again (#{answer})"
            answer = nil
          end
        end
          @interface.save() if answer == "Y"
        end
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
        puts "`1` Search for meal by name (not Implimented)"
        puts "`2` Show meals by a category"
        puts "`3` Show meals by a main ingrediant (not Implimented)"
        puts "`4` Show me a random meal"
        puts "`5` View favorite meals" if !Meal.favorites.empty?
        puts "`6` Clear all favorite meals" if !Meal.favorites.empty?
        puts '`0` Exit program' if !Meal.favorites_changed?
        puts '`0` Exit program (don`t save favorite change)' if Meal.favorites_changed?
        puts '`-1` Exit program  and save favorites' if Meal.favorites_changed?

        input_phase = true
        while !quit && input_phase
          print "$: "
          input = begin
            Integer(gets.chomp)
          rescue ArgumentError
            -99
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
            show_meal(@interface.random_meal)
            input_phase = false
          when 5
            if !Meal.favorites.empty?
              show_full_list(Meal.favorites)
            else
              puts "No Favorites to view"
            end
            sleep 1 # Development
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
            input_phase = false
            quit = true
          when -1
            if Meal.favorites_changed?
              puts "Saving favorite changes"
              Meal.save_favorite
              input_phase = false
              quit = true
            else
              puts "Invalid selection, please try again"
            end
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
          list_meals(@interface.meals_by_category(Meal.categories[choice-1]))
        else
          choice = nil
          puts "Invalid input, please try again"
        end
      end
      puts "Press enter to return to menu" if choice != 0 # development
      print "$: "
      gets.chomp if choice != 0  # development
    end

    def get_meals_by_main_ingrediant
      puts "Show meal by main ingrediant"
      sleep 1
    end

    def show_full_list(meals)
      # List full meals from hash
      raise "Meals is not a hash" unless meals.is_a?(Hash)

      count = 0
      round = {}
      clear()
      puts "Select a meal below:"
      meals.collect do |key, value|
        count += 1
        round[count] = key
        puts "`#{count}` #{value.name}"
      end
      puts '`0` to return to menu'

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
      sleep 1

      show_meal(meals[round[input]])
    end

    def show_partial_list(meals)
      # List meals to front end for selection
      # If array only has one meal it will directly show that meal.
      raise 'meals is empty' if meals.empty?
      # TODO
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

    def clear()
      # Marks old Input and clears screen
      puts "=== old console Output ==="
      puts `clear`
    end
  end
end
