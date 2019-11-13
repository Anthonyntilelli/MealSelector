# frozen_string_literal: true

require 'open-uri'
require 'json'
require_relative "meal.rb" 

module MealSelector
  # Communicates with Mealdb database for meal data
  # Network issue will raised exceptions which are expected to handle by caller
  class ApiInterface
    API_ENDPOINT = 'https://www.themealdb.com/api/json'

    def initialize(key, version)
      # Sets API key and Version
      # Set api_key and check its correct format
      raise 'Key must a string' unless key.is_a?(String)

      begin
        Integer(key)
      rescue ArgumentError
        raise 'API must be a number'
      end
      warn('Warning: API key `1` is only for development') if key == '1'
      raise 'version must be integer above or equal to one' \
      unless version.is_a?(Integer) && version.to_i >= 1
      @version = version
      @key = key
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
      connection = open("#{api_url}random.php").each do |json|
        raw_content = json
      end
      connection.close
      json_meal = JSON.parse(raw_content)
      meal = MealSelector::Meal.new(json_meal["meals"][0])
    end

    def list_all_meal_categories
      # List all meal categories
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/categories.php
    end

    def populate_categories
      # Gets List of Categories for meals and set them.
      # List all Categories
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/list.php?c=list

      raw_categories = nil
      connection = open("#{api_url}list.php?c=list").each do |json|
        raw_categories = json
      end
      connection.close
      MealSelector::Meal.set_categories(JSON.parse(raw_categories)['meals'])
    end

    def search_by_ingredient(primary_ingredient)
      # Search by primary ingredient
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
    end

    def meals_by_main_ingredient(main_ingredient)
      # Filter by main ingredient
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
    end

    def meals_by_category(category)
      # Filter by Category
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
    end

    def save(path = '~/.Mealdbkey')

      # Saves api_key and version to a file
    end

    def self.load(path = '~/.Mealdbkey')
      # Load api_key and version from a file
    end

    private

    def api_url
      API_ENDPOINT + "/v#{@version}/#{@key}/"
    end

  end
end
