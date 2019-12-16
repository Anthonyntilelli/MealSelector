# frozen_string_literal: true

module MealSelector
  # User interface for MealSelector actions
  # @author Anthony Tilelli
  class Frontend
    attr_accessor :last_meal

    def initialize
      @last_meal = nil
    end

    def self.clear
      # Marks old Input and clears screen
      puts '=== old console Output ==='
      puts `clear`
    end

    def self.user_input(list_size, *chars)
      # prompts  user input and check if allowed input
      # Assume starts with 1 (negative are invalid)
      # set list_size to 0 to not accept numbers
      # '' in *chars will allow for just enter
      # user_input is returned as downsized string
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

    def show_meal(meal, menu_only, backend)
      # Shows a meal
      # menu_only determine if option to go back is allowed
      # return if previous list should repeat [t/f]
      raise "meal is not a MealSelector::Meal, instead #{meal.class}" unless meal.is_a?(Meal)
      raise 'backend is not a backend' unless backend.is_a?(Backend)

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

    def show_meal_list(meals, menu_only, backend)
      # List meals
      # menu_only determine if option to go back is allowed
      # return if previous section should repeat [t/f]
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

    def search_meal_by_name(backend)
      # Search for meal by entered name
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

    def meals_by_categories(backend)
      # List categories user can choose from
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

    def meals_by_main_ingrediant(backend)
      # Search for meal by main ingrediant
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

    def show_meal_actions(backend, meal, menu_only)
      # executes options for show meal
      # return if previous list should repeat [t/f]
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
        Launchy.open(meal.youtube)
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

      raise "Unknown choice #{choice}"
    end
  end
end
