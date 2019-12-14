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
      # calls front end's menu
      @frontend.menu
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
  end
end
