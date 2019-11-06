module MealSelector
  class API_INTERFACE
    API_ENDPOINT = "https://www.themealdb.com/api"

    def initialize(key, version)
      # Sets API key and Version
      
      # Set api_key and check its correct format
      raise "Key must a string" unless key.is_a?(String)
      Integer(key) rescue raise "API must be a number"
      warn("Warning: API key `1` is only for development") if key == "1"
      @API_KEY = KEY

      # sets api_version
      raise "version must be integer above or equal to one" unless version.is_a?(Integer) && version.to_i >= 1
      @API_VERSION = version
    end

    def search_meal_name(name)
      # Search meal by name
      # https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
    end

    def meal_by_id(id)
      # Lookup full meal details by id
      # https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772
    end

    def random_meal
      # Lookup a single random meal
      # https://www.themealdb.com/api/json/v1/1/random.php
    end

    def list_all_meal_categories
        # List all meal categories
        # https://www.themealdb.com/api/json/v1/1/categories.php
    end

    def populate_lists
        # List all Categories and Ingredients
        # https://www.themealdb.com/api/json/v1/1/list.php?c=list
        # https://www.themealdb.com/api/json/v1/1/list.php?i=list
    end

    def meals_by_main_ingredient(main_ingredient)
        # Filter by main ingredient
        # https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
    end
    
    def meals_by_category(category)
        # Filter by Category
        # https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
    end
    
    def save_api_key(path = "~/.Mealdbkey")
      # Saves api_key to a file
    end

  end
end
