# frozen_string_literal: true

module MealSelector
  # User interface for MealSelector
  class Frontend
    def initialize
      # Trys to load key from file and ask if file does not exist/bad format
      @last_meal = nil
      new_interface = nil
      begin
        @backend = Backend.new(ApiInterface.load)
      rescue
        @backend = nil
      end

      # => No key file found
      until @backend
        puts 'To start using Meal Selector, please input below info:'
        print 'API KEY ("q" will kill the program): '
        key = gets.chomp
        exit if key == 'Q' || key == 'q'
        print 'Version: '
        version = gets.chomp
        exit if version == 'Q' || version == 'q'
        begin
          new_interface = ApiInterface.new(key, version)
          @backend = Backend.new(new_interface)
        rescue
          puts 'Error when setting up key and version, try again.'
          puts 'Please ensure correct key is in use'
          puts ''
          @backend = nil
          new_interface = nil
        end
      end
      save_dialog(new_interface) if new_interface
      # => No key file found
    end

    def menu
      quit = false
      until quit
        allowed_array = ['quit']
        clear
        puts 'Thank you for using Meal Selector.'
        puts 'Please select a number from the options below:'
        puts '`1` Search for meal by name'
        puts '`2` Show meals by a category'
        puts '`3` Search meals by a main ingrediant'
        puts '`4` Show a random meal'
        if @last_meal
          puts "`l` Show `#{@last_meal.name}` again"
          allowed_array << 'l'
        end
        unless @backend.favorites.empty?
          puts '`f` View favorite meals'
          puts '`c` Clear all favorite meals'
          allowed_array << 'f'
          allowed_array << 'c'
        end
        if @backend.favorites_changed?
          puts '`save` Save favorites and exit'
          puts '`quit` Exit program without saving favorites'
          allowed_array << 'save'
        else
          puts '`quit` Exit program'
        end

        input = user_input(4, *allowed_array)
        case input
        when '1'
          search_meal_by_name
        when '2'
          meals_by_categories
        when '3'
          meals_by_main_ingrediant
        when '4'
          # Showing Random meal
          show_meal(@backend.find_random_meal, true)
        when 'l'
          # Show last meal
          show_meal(@last_meal, true)
        when 'f'
          # show favorites
          show_meal_list(@backend.favorites, true)
        when 'c'
          print 'Are you sure?[y/n]: '
          user_confirmation = gets.chomp.downcase
          if user_confirmation == 'y'
            puts 'Clearing favorites'
            @backend.favorites.clear
          elsif user_confirmation == 'n'
            puts 'aborting clear'
          else
            puts 'unknown input, assuming no'
          end
          sleep 1
        when 'quit'
          puts 'Quiting'
          quit = true
        when 'save' || 'w'
          puts 'Saving favorite changes and exiting'
          @backend.save_favorite
          quit = true
        else
          raise "Invalid selection in case (#{input})"
        end
        sleep 0.5 # delay clearing screen
      end
    end

    private

    def clear
      # Marks old Input and clears screen
      puts '=== old console Output ==='
      puts `clear`
    end

    def save_dialog(api)
      # Ask user if they want to save api and version info
      answer = nil
      until answer
        print 'Save API Key and Version [Y/N]? '
        answer = gets.strip.upcase
        if answer != 'N' && answer != 'Y'
          puts "Invalid input, try again (#{answer})"
          answer = nil
        end
      end
      api.save if answer == 'Y'
    end

    def user_input(list_size, *chars)
      # prompts  user input and check if allowed input
      # Assume starts with 1 (0 or negative are invalid)
      # set list_size to 0 to not accept numbers
      # '' in *chars will allow for just enter
      # user_input is returned as downsized string
      raise 'list_size cannot be negative' if list_size.negative?

      user_input = :not_set
      while user_input == :not_set
        print '$: '
        input = gets.chomp.downcase
        return input if chars.include?(input)
        begin
          raise ArgumentError.new('Not in range') unless Integer(input).between?(1, list_size)
          user_input = input
        rescue ArgumentError
          user_input = :not_set
          puts 'Invalid Input, please try again'
        end
      end
      user_input
    end

    def show_meal(meal, menu_only)
      # Shows a meal
      # menu_only determine if option to go back is allowed
      # return if previous list should repeat [t/f]
      raise "meal is not a MealSelector::Meal, instead #{meal.class}" unless meal.is_a?(Meal)
      raise 'meal is not frozen' unless meal.frozen?

      clear
      @last_meal = meal
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
      puts meal.instructions
      puts ''

      allowed_input = ['m']
      if @backend.favorites[id].nil?
        unless menu_only
          puts 'Enter `f` to add to favorites and go back'
          allowed_input << 'f'
        end
        puts 'Enter `fm` to add to favorites and go to menu'
        allowed_input << 'fm'
      else
        unless menu_only
          puts 'Enter `r` to remove from favorites and go back'
          allowed_input << 'r'
        end
        puts 'Enter `rm` to remove from favorites and go to menu'
        allowed_input << 'rm'
      end
      unless menu_only
        puts 'Enter `b` to go back'
        allowed_input << 'b'
      end
      puts 'Enter `m` to go menu'
      input = user_input(0, *allowed_input)
      if input == 'f' || input == 'fm'
        puts 'Adding to favorites'
        @backend.add_to_favorites(meal)
        input == 'f' ? (return true) : (return false)
      elsif input == 'r' || input == 'rm'
        puts 'Removing favorite'
        @backend.favorites.delete(id)
        input == 'r' ? (return true) : (return false)
      elsif input == 'b'
        return true
      elsif input == 'm'
        return false
      else
        raise "Unknown input: #{input}"
      end
    end

    def show_meal_list(meals, menu_only)
      # List meals
      # menu_only determine if option to go back is allowed
      # return if previous section should repeat [t/f]
      raise 'meals is empty' if meals.empty?
      raise 'Meals is not a hash of meals' unless meals.is_a?(Hash)

      repeating = true
      while repeating
        allowed_input = ['m']
        count = 0
        round = {} # record the keys per round {round => id }
        clear
        puts 'Select a meal below:'
        # Output meal name
        meals.collect do |key, meal|
          count += 1
          round[count.to_s] = key
          puts "`#{count}` #{meal.name}"
        end
        puts 'Press `m` to go to menu'
        unless menu_only
          puts 'Press `b` to go back'
          allowed_input << 'b'
        end

        input = user_input(round.size, *allowed_input)
        return true if input == 'b'
        return false if input == 'm'

        meal_object = if meals[round[input]].whole_meal?
                        meals[round[input]]
                      else
                        # Partial meal => resolve id to get full meal
                        @backend.find_meal_by_id(round[input].to_s.to_i)
                      end
        repeating = show_meal(meal_object, false)
      end
    end

    def search_meal_by_name
      # Search for meal by entered name
      repeat = true
      while repeat
        clear
        puts 'Enter a meal name to search:'
        puts 'Press `m` to return to menu'
        print '$: '
        user_input = gets.chomp.downcase
        next if user_input == ''
        return if user_input == 'm'

        results = @backend.find_meals_by_name(user_input)
        if results == {}
          puts 'Cannot find any meals by that name, try Again'
          sleep 0.75
        else
          repeat = show_meal_list(results, false)
        end
      end
    end

    def meals_by_categories
      # List categories user can choose from
      repeat = true
      while repeat
        clear
        puts 'Select a meal category:'
        @backend.categories.each_index do |index|
          puts "=> `#{index + 1}` #{@backend.categories[index]}"
        end
        puts 'Press `m` Return to menu'
        input = user_input(@backend.categories.size, 'm')
        return if input == 'm'

        category = @backend.categories[input.to_i - 1]
        repeat = show_meal_list(@backend.find_meals_by_categories(category), false)
      end
    end

    def meals_by_main_ingrediant
      # Search for meal by main ingrediant
      repeat = true
      while repeat
        clear
        puts 'Enter an ingrediant to search by:'
        puts 'Enter `m` to return to menu'
        print '$: '
        user_input = gets.chomp.downcase
        next if user_input == ''
        return if user_input == 'm'

        results = @backend.find_meal_by_ingredient(user_input)
        if results == {}
          puts 'Cannot find any meals for that ingredient, try Again'
          sleep 0.75
        else
          repeat = show_meal_list(results, false)
        end
      end
    end
  end
end
