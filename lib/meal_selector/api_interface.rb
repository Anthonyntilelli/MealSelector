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
      raise "Name is not a string" unless name.is_a?(String)
      name = name.gsub(" ","%20")

      raw_content = nil
      connection = open("#{api_url}search.php?s=#{name}").each do |json|
        raw_content = json
      end
      connection.close
      json_meal = JSON.parse(raw_content)
      MealSelector::Meal.create_from_array(json_meal)
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
      ApiInterface.new(raw_data[3], raw_data[1].to_i)
    end

    private

    def api_url
      API_ENDPOINT + "/v#{@version}/#{@key}/"
    end

  end
end
