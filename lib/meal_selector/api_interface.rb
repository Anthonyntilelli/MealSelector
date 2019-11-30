# frozen_string_literal: true

module MealSelector
  # Communicates with Mealdb database for meal data
  # Network issue can raise exceptions, which are expected to handle by caller
  class ApiInterface
    API_ENDPOINT = 'https://www.themealdb.com/api/json'

    def initialize(key, version)
      # Sets API key and Version
      # Set api_key and check its correct format
      raise 'Key must a string' unless key.is_a?(String)
      raise 'Version must be 1 or 2' unless version == '1' || version == '2'

      warn('Warning: API key `1` is only for development') if key == '1'

      @version = version
      @key = key
    end

    def search_meal_name(name)
      # Search meal by name
      # return array of Meals
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
      raise 'Name is not a string' unless name.is_a?(String)
      name = name.gsub(" ","%20")

      raw_content = nil
      connection = open("#{api_url}search.php?s=#{name}").each do |json|
        raw_content = json
      end
      connection.close
      json_meal = JSON.parse(raw_content)
      Meal.create_from_array(json_meal)
    end

    def meal_by_id(id)
      # Lookup full meal details by id
      # return array of Meals
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772

      raise "id is not an Integer (#{id.class})" unless id.is_a?(Integer)

      raw_content = nil
      connection = open("#{api_url}lookup.php?i=#{id}").each do |json|
        raw_content = json
      end
      connection.close
      create_meal(raw_content)
    end

    def random_meal
      # Lookup a single random meal
      # returns meal object
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/random.php
      raw_content = nil
      connection = open("#{api_url}random.php").each do |json|
        raw_content = json
      end
      connection.close
      create_meal(raw_content)
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
      Meal.set_categories(JSON.parse(raw_categories)['meals'])
    end

    def search_by_ingredient(primary_ingredient)
      # Search by primary main ingredient
      # Returns MealList
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
      raise 'primary_ingredient is not a string' unless primary_ingredient.is_a?(String)
      primary_ingredient = primary_ingredient.gsub(" ","%20")

      raw_content = nil
      connection = open("#{api_url}filter.php?i=#{primary_ingredient}").each do |json|
        raw_content = json
      end
      connection.close
      json_meal = JSON.parse(raw_content)
      MealList.new(json_meal)
    end

    def meals_by_category(category)
      # Filter by Category
      # Returns MealList
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
      populate_categories if Meal.categories.empty? || Meal.categories.nil?
      raise "#{category} is not a valid category" unless Meal.categories.include?(category)

      raw_content = nil
      connection = open("#{api_url}filter.php?c=#{category}").each do |json|
        raw_content = json
      end
      connection.close
      json_meal = JSON.parse(raw_content)
      MealList.new(json_meal)
    end

    def save(path = "#{Dir.home}/.Mealdbkey")
      # Saves ApiInterface to a file (will overwrite existing file)
      File.open(path, 'w') { |file| file.write("version: #{@version}\nkey: #{@key}") }
    end

    def self.load(path = "#{Dir.home}/.Mealdbkey")
      # Creates ApiInterface from a file
      raise "File #{path} does not exist!" unless File.exist?(path)
      raw_data = File.read(path).chomp
      raw_data = raw_data.split
      raise 'Incorrect format for Meal Api Key file' unless raw_data.count == 4
      raise "Error finding version info (#{raw_data[0]})" unless raw_data[0] == 'version:'
      raise "Error finding key info (#{raw_data[2]})" unless raw_data[2] == 'key:'
      ApiInterface.new(raw_data[3], raw_data[1])
    end

    private

    def api_url
      API_ENDPOINT + "/v#{@version}/#{@key}/"
    end

    def create_meal(raw_meal_content)
      # Parse Meal return and create meal object
      parsed_meal = JSON.parse(raw_meal_content)['meals']
      return nil if parsed_meal.nil?
      raise "Incorrect number of meals returned" if parsed_meal.count != 1
      Meal.new(parsed_meal[0])
    end

  end
end
