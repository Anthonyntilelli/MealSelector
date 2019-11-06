module MealSelector
  class Frontend
    def initialize
    end

    def welcome
      puts "Thank you for choosing Meal Selector."
    end

    def menu(last_meal)
      raise TypeError unless !!last_meal == last_meal
      puts "Please select a number from the options below to begin."
      puts "1. Search for meal by name"
      puts "2. Show meals by a category"
      puts "3. Show meals by a main ingrediant"
      puts "4. Show me a random meal"
      puts "5. Show prevous meal" if last_meal
    end

    def search_meal_by_name(name)
    end

    def get_categories_and_ingredients
    end

    def get_meals_by_categories(category)
    end

    def get_meals_by_main_ingrediant(ingrediant)
    end

    def get_random_meal
    end
    
  end
end
