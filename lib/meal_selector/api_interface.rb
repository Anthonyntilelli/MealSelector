# frozen_string_literal: true

module MealSelector
  # Communicates with Mealdb database and return meal hash
  # Network issue can raise exceptions, which are expected to handle by caller
  class ApiInterface
    API_ENDPOINT = 'https://www.themealdb.com/api/json'
    DEFAULT_KEY_PATH = "#{Dir.home}/.Mealdbkey"

    def initialize(key, version)
      # Sets API key and Version
      # Set api_key and check its correct format
      raise 'Key must a string' unless key.is_a?(String)
      raise 'Version must be 1 or 2' unless %w[1 2].include?(version)

      warn('Warning: API key `1` is only for development') if key == '1'
      @version = version
      @key = key
      @api_url = API_ENDPOINT + "/v#{@version}/#{@key}/"
    end

    def search_meals_name(name)
      # Search meal(s) by name
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
      raise "Name is not a string (#{name.class})" unless name.is_a?(String)

      url_end = "search.php?s=#{name.gsub(' ', '%20')}"
      content = api_call(url_end)
      validate(content)
      content
    end

    def meal_by_id(id)
      # Lookup full meal details by id
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772
      raise "id is not an Integer (#{id.class})" unless id.is_a?(Integer)

      content = api_call("lookup.php?i=#{id}")
      validate(content)
      content
    end

    def random_meal
      # Lookup a single random meal
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/random.php
      content = api_call('random.php')
      validate(content)
      content
    end

    def meal_categories
      # Gets List of Categories for meals
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/list.php?c=list
      content = api_call('list.php?c=list')
      validate(content)
      content
    end

    def search_by_ingredient(primary_ingredient)
      # Search by primary main ingredient
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
      raise 'primary_ingredient is not a string' unless primary_ingredient.is_a?(String)

      url_end = "filter.php?i=#{primary_ingredient.gsub(' ', '%20')}"
      content = api_call(url_end)
      validate(content)
      content
    end

    def meals_by_category(category)
      # Filter by Category
      # EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
      raise "category is not a string (#{category.class})" unless category.is_a?(String)

      content = api_call("filter.php?c=#{category}")
      validate(content)
      content
    end

    def can_save?
      # returns if key can save
      @key != '1'
    end

    def save(path = DEFAULT_KEY_PATH)
      # Saves ApiInterface to a file (will overwrite existing file)
      raise 'cannot save debug key' unless can_save?

      File.open(path, 'w') \
      { |file| file.write("version: #{@version}\nkey: #{@key}") }
    end

    def self.load(path = DEFAULT_KEY_PATH)
      # Creates ApiInterface from a file
      raise "File #{path} does not exist!" unless File.exist?(path)

      raw_data = File.read(path).chomp
      raw_data = raw_data.split
      raise 'Incorrect format for Meal Api Key file' unless raw_data.count == 4
      raise "Error finding version info (#{raw_data[0]})" unless raw_data[0] == 'version:'
      raise "Error finding key info (#{raw_data[2]})" unless raw_data[2] == 'key:'

      new(raw_data[3], raw_data[1])
    end

    private

    def api_call(endpoint)
      # makes api call and returns parsed data
      # on error will retry 3 times
      raise 'endpoint must be string' unless endpoint.is_a?(String)

      url = @api_url.to_s + endpoint.to_s
      tries = 3
      begin
        tries -= 1
        res = HTTParty.get(url, timeout: 25, format: :plain)
      rescue Net::OpenTimeout, SocketError
        raise unless tries >= 0

        puts "Failed to reach meal server, Retrying...(#{tries + 1})"
        sleep rand(1..3)
        retry
      end
      raise "Error when calling `#{url}` responce:`#{res.response}`" unless res.success?

      JSON.parse(res, symbolize_names: true)
    end

    def validate(data)
      # validate data in expected format and raise exception if not
      raise "responce is not in hash (#{data})" unless data.is_a?(Hash)
      raise 'responce missing `:meals` entry' unless data.keys.include?(:meals)
    end
  end
end
