require 'open-uri'
require 'json'

module MealSelector
  class API_INTERFACE
    # Communicates with Mealdb database for meal data
    # Will raise error on network issue, expected to handle errors outside of class.

    API_ENDPOINT = "https://www.themealdb.com/api"

    def initialize(key, version)
      # Sets API key and Version
      
      # Set api_key and check its correct format
      raise "Key must a string" unless key.is_a?(String)
      Integer(key) rescue raise "API must be a number"
      warn("Warning: API key `1` is only for development") if key == "1"
      @API_KEY = key

      # sets api_version
      raise "version must be integer above or equal to one" unless version.is_a?(Integer) && version.to_i >= 1
      @API_VERSION = version.to_s
    end

    def search_meal_name(name)
      # Search meal by name
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
    end

    def meal_by_id(id)
      # Lookup full meal details by id
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772
    end

    def random_meal
      # Lookup a single random meal
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/random.php
      raw_content = nil
      connection = open("https://www.themealdb.com/api/json/v#{@API_VERSION}/#{@API_KEY}/random.php").each {|json| raw_content = json }
      connection.close
      json_meal = JSON.parse(raw_content)
      # to do conver to meal
    end

    def list_all_meal_categories
        # List all meal categories
        # EXAMPLE: https://www.themealdb.com/api/json/v1/1/categories.php
    end

    def populate_lists
        # List all Categories and Ingredients
        # EXAMPLE: https://www.themealdb.com/api/json/v1/1/list.php?c=list
        # EXAMPLE: https://www.themealdb.com/api/json/v1/1/list.php?i=list
    end

    def meals_by_main_ingredient(main_ingredient)
        # Filter by main ingredient
        # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
    end
    
    def meals_by_category(category)
        # Filter by Category
        # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
    end
    
    def save_api_key(path = "~/.Mealdbkey")
      # Saves api_key and version to a file
    end

    def self.load(path = "~/.Mealdbkey")
      # Load api_key and version from a file
    end

  end
end
