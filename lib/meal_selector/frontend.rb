module MealSelector
  class Frontend
    def initialize()
    end

    def welcome
      clear()
      puts "Thank you for choosing Meal Selector."
    end

    def menu()
      quit = false
      input_phase = true
      while !quit
        puts "Please select a number from the options below:"
        puts "`1` Search for meal by name"
        puts "`2` Show meals by a category"
        puts "`3` Show meals by a main ingrediant"
        puts "`4` Show me a random meal"
        #TODO puts "5. View a past meals"
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
            raise NotImplementedError
            input_phase = false
          when 2
            raise NotImplementedError
            input_phase = false
          when 3
            raise NotImplementedError
            input_phase = false
          when 4
            get_random_meal()
            input_phase = false
          when 5
            raise NotImplementedError
            input_phase = false
          when 0
            input_phase = false
            quit = true
          else
            puts "Invalid selection, please try again"
          end
        end
        clear
      end
    end

    def search_meal_by_name(name)
    end

    def get_meals_by_categories(category)
    end

    def get_meals_by_main_ingrediant(ingrediant)
    end

    def get_random_meal()
      puts "Showing Random meal"
    end
    
    def clear()
      # Marks old Input and clears screen
      puts "=== old console Output ==="
      puts `clear`
    end
  end
end
