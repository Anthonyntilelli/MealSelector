# frozen_string_literal: true

# MealSelector
# @author Anthony Tilelli
module MealSelector
  # Menu for MealSelector
  class MealSelector
    # Set up Frontend and Backend
    def initialize
      # Trys to load key from file
      begin
        @backend = Backend.new(ApiInterface.load)
      rescue RuntimeError
        @backend = nil
      end
      # Asks for api/key if file does not exist/bad format
      if @backend.nil?
        @backend = init_kv_dialog
        init_save_dialog
      end
      @frontend = Frontend.new
    end

    # Main menu for Meal Selector
    # @return [void]
    def menu
      quit = false
      until quit
        Frontend.clear
        puts 'Thank you for using Meal Selector.'
        puts 'Please select a number from the options below:'
        puts '`1` Search for meal by name'
        puts '`2` Show meals by a category'
        puts '`3` Search meals by a main ingrediant'
        puts '`4` Show a random meal'
        allowed_input = meal_second_half
        input = Frontend.user_input(4, *allowed_input)
        quit =  menu_dispatcher(input)
        sleep 0.5 # delay clearing screen
      end
    end

    private

    # Get key and version from user
    # return  backend
    def init_kv_dialog
      backend = nil
      while backend.nil?
        puts 'To start using Meal Selector, please input below info:'
        print 'API KEY ("q" will kill the program): '
        key = gets.chomp.downcase
        exit if key == 'q'
        print 'Version: '
        version = gets.chomp.downcase
        exit if version == 'q'
        begin
          backend = Backend.new(ApiInterface.new(key, version))
        rescue RuntimeError
          puts 'Error when setting up key and version, try again.'
          puts 'Please ensure correct key is in use'
          backend = nil
        end
      end
      backend
    end

    # Ask user if they want to save api and version info
    def init_save_dialog
      return if @backend.nil?
      return unless @backend&.api_can_save?

      answer = nil
      until answer
        print 'Save API Key and Version [Y/N]? '
        answer = gets.strip.upcase
        if answer != 'N' && answer != 'Y'
          puts "Invalid input, try again (#{answer})"
          answer = nil
        end
      end
      @backend.save_api_info if answer == 'Y'
    end

    # returns allowed input
    def meal_second_half
      allowed_array = ['quit']
      if @frontend.last_meal
        puts "`l` Show `#{@frontend.last_meal.name}` again"
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
      allowed_array
    end

    # Runs endusers selection
    # returns quit [t/f]
    def menu_dispatcher(input)
      quit = false
      case input
      when '1'
        @frontend.search_meal_by_name(@backend)
      when '2'
        @frontend.meals_by_categories(@backend)
      when '3'
        @frontend.meals_by_main_ingrediant(@backend)
      when '4'
        # Showing Random meal
        @frontend.show_meal(@backend.find_random_meal, true, @backend)
      when 'l'
        # Show last meal
        @frontend.show_meal(@frontend.last_meal, true, @backend)
      when 'f'
        # show favorites
        @frontend.show_meal_list(@backend.favorites, true, @backend)
      when 'c'
        favorite_clear_dialog
      when 'quit'
        puts 'Quiting'
        quit = true
      when 'save'
        puts 'Saving favorite changes and exiting'
        @backend.save_favorites
        quit = true
      else
        raise "Invalid selection in case (#{input})"
      end
      quit
    end

    # Ask user if they want to clear favorites
    def favorite_clear_dialog
      print 'Are you sure?[y/n] '
      user_confirmation = Frontend.user_input(0, 'y', 'n')
      if user_confirmation == 'y'
        puts 'Clearing favorites'
        @backend.favorites.clear
      elsif user_confirmation == 'n'
        puts 'aborting clear'
      end
    end
  end
end
