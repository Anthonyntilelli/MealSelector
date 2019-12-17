# frozen_string_literal: true

module MealSelector
  # User interface for MealSelector actions
  # @author Anthony Tilelli
  class Frontend
    attr_accessor :last_meal

    def initialize
      @last_meal = nil
    end

    # Marks old console output and clears screen
    # @return [void]
    def self.clear
      puts '==== old console Output above ===='
      puts `clear`
    end

    # prompts  user input and check if allowed input
    # @param list_size [Integer] must be positive number or Zero,
    #  set to `0` to not accept numbers
    # @param chars [Array<String>] list of allowed characters,
    #  enter `''` to allow just enter without char or number
    # @return [String.downcase]
    def self.user_input(list_size, *chars)
      # Number input starts with 1.
      raise 'list_size must be an integer' unless list_size.is_a?(Integer)
      raise 'list_size cannot be negative' if list_size.negative?

      input = nil
      while input.nil?
        print '$: '
        input = gets&.chomp&.downcase
        # Allowed char
        return input if chars.include?(input)
        # Num in range
        return input if input.to_i.between?(1, list_size)

        # incorrect input
        input = nil
        puts 'Invalid Input, please try again'
      end
    end

    # Shows a whole meal
    # @param meal [Meal] one Meal
    # @param menu_only [Boolean] Determines if the back option should be allowed
    #  (`back` option allowed on false)
    # @param backend [Backend]
    # @raise when meal is not a whole_meal
    # @return [Boolean] previous section should repeat
    def show_meal(meal, menu_only, backend)
      raise "meal is not a MealSelector::Meal, instead #{meal.class}" unless meal.is_a?(Meal)
      raise 'meal is not whole' unless meal.whole_meal?
      raise 'backend is not a Backend' unless backend.is_a?(Backend)

      Frontend.clear
      @last_meal = meal
      puts "Name: #{meal.name.capitalize}"
      puts "Category: #{meal.category.capitalize}"
      puts "Type: #{meal.type.capitalize}"
      puts 'Ingredient:'
      meal.ingredient.each do |item, amount|
        puts "=> #{item}: #{amount}"
      end
      puts 'Instructions:'
      puts meal.instructions
      puts ''
      show_meal_actions(backend, meal, menu_only)
    end

    # List meals provided
    # @param meals [Hash] One or more meals
    # @param menu_only [Boolean] Determines if the back option should be allowed
    #  (`back` option allowed on false)
    # @param backend [Backend]
    # @return [Boolean] previous section should repeat
    def show_meal_list(meals, menu_only, backend)
      raise 'Meals is not a hash of meals' unless meals.is_a?(Hash)
      raise 'meals is empty' if meals.empty?
      raise 'backend is not a backend' unless backend.is_a?(Backend)

      repeating = true
      while repeating
        allowed_input = ['m']
        count = 0
        round = {} # record the keys per round {round => id }
        Frontend.clear
        puts 'Select a meal below:'
        # Output meal name
        meals.each do |key, meal|
          count += 1
          round[count.to_s] = key
          puts "`#{count}` #{meal.name}"
        end
        puts 'Press `m` to go to menu'
        unless menu_only
          puts 'Press `b` to go back'
          allowed_input << 'b'
        end
        input = Frontend.user_input(round.size, *allowed_input)
        return true if input == 'b'
        return false if input == 'm'

        meal = backend.resolve_meal(meals[round[input]])
        repeating = show_meal(meal, false, backend)
      end
    end

    # Search for meal by name
    # @param backend [Backend]
    # @return [void]
    def search_meal_by_name(backend)
      repeat = true
      while repeat
        Frontend.clear
        puts 'Enter a meal name to search:'
        puts 'Press `m` to return to menu'
        print '$: '
        input = gets.chomp.downcase
        next if input == ''
        return if input == 'm'

        results = backend.find_meals_by_name(input)
        if results == {}
          puts 'Cannot find any meals by that name, try Again'
          sleep 0.75
        else
          repeat = show_meal_list(results, false, backend)
        end
      end
    end

    # List categories user can choose from.
    # @param backend [Backend]
    # @return [void]
    def meals_by_categories(backend)
      repeat = true
      while repeat
        Frontend.clear
        puts 'Select a meal category:'
        backend.categories.each_index do |index|
          puts "=> `#{index + 1}` #{backend.categories[index]}"
        end
        puts 'Press `m` Return to menu'
        input = Frontend.user_input(backend.categories.size, 'm')
        return if input == 'm'

        category = backend.categories[input.to_i - 1]
        repeat = show_meal_list(backend.find_meals_by_categories(category), false, backend)
      end
    end

    # Search for meal by main ingrediant.
    # @param backend [Backend]
    # @return [void]
    def meals_by_main_ingrediant(backend)
      repeat = true
      while repeat
        Frontend.clear
        puts 'Enter an ingrediant to search by:'
        puts 'Enter `m` to return to menu'
        print '$: '
        input = gets.chomp.downcase
        next if input == ''
        return if input == 'm'

        results = backend.find_meal_by_ingredient(input)
        if results == {}
          puts 'Cannot find any meals for that ingredient, try Again'
          sleep 0.75
        else
          repeat = show_meal_list(results, false, backend)
        end
      end
    end

    private

    # Executes options for show meal
    # @return [Boolean] if previous list should repeat
    def show_meal_actions(backend, meal, menu_only)
      allowed_input = ['m']
      if backend.favorites[meal.id].nil?
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
      if meal.youtube
        puts 'Enter `v` to open meal video'
        allowed_input << 'v'
      end
      puts 'Enter `m` to go menu'
      choice = Frontend.user_input(0, *allowed_input)
      # Action
      if choice == 'v'
        puts "Launching #{meal.youtube}"
        suppress_output { Launchy.open(meal.youtube) }
        allowed_input.pop # remove v
        puts 'Select another option:'
        choice = Frontend.user_input(0, *allowed_input)
      end
      if %w[f fm].include?(choice)
        puts 'Adding to favorites'
        backend.add_to_favorites(meal)
        choice == 'f' ? (return true) : (return false)
      elsif %w[r rm].include?(choice)
        puts 'Removing favorite'
        backend.favorites.delete(meal.id)
        choice == 'r' ? (return true) : (return false)
      end
      return true if choice == 'b'
      return false if choice == 'm'

      raise "Unknown choice: #{choice}"
    end

    # Disables print for duration of block
    def suppress_output
      original_stdout = $stdout.clone
      original_stderr = $stderr.clone
      $stderr.reopen File.new('/dev/null', 'w')
      $stdout.reopen File.new('/dev/null', 'w')
      yield
    ensure
      $stdout.reopen original_stdout
      $stderr.reopen original_stderr
    end
  end
end
