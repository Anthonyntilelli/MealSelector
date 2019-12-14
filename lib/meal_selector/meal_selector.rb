# frozen_string_literal: true

module MealSelector
  # Menu for MealSelector
  class MealSelector
    def initialize
      # created api and set up frontend
      # Trys to load key from file
      begin
        backend = Backend.new(ApiInterface.load)
      rescue RuntimeError
        backend = nil
      end
      # Asks for api/key if file does not exist/bad format
      if backend.nil?
        backend = init_kv_dialog
        init_save_dialog(backend) if backend&.api_can_save?
      end
      @frontend = Frontend.new(backend)
    end

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
        quit =  @frontend.menu_dispatcher(input)
        sleep 0.5 # delay clearing screen
      end
    end

    private

    def init_kv_dialog
      # Get key and version from user
      # return  backend

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

    def init_save_dialog(backend)
      # Ask user if they want to save api and version info
      return if backend.nil?

      answer = nil
      until answer
        print 'Save API Key and Version [Y/N]? '
        answer = gets.strip.upcase
        if answer != 'N' && answer != 'Y'
          puts "Invalid input, try again (#{answer})"
          answer = nil
        end
      end
      backend.save_api_info if answer == 'Y'
    end

    def meal_second_half
      # returns allowed input
      allowed_array = ['quit']
      if @frontend.last_meal
        puts "`l` Show `#{@frontend.last_meal.name}` again"
        allowed_array << 'l'
      end
      unless @frontend.backend.favorites.empty?
        puts '`f` View favorite meals'
        puts '`c` Clear all favorite meals'
        allowed_array << 'f'
        allowed_array << 'c'
      end
      if @frontend.backend.favorites_changed?
        puts '`save` Save favorites and exit'
        puts '`quit` Exit program without saving favorites'
        allowed_array << 'save'
      else
        puts '`quit` Exit program'
      end
      allowed_array
    end
  end
end
