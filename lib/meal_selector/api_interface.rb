# frozen_string_literal: true

module MealSelector
  # Communicates with Mealdb database
  # @raise network issue can raise exceptions
  class ApiInterface
    # URL to mealdb
    API_ENDPOINT = 'https://www.themealdb.com/api/json'
    # Default path for key and version
    DEFAULT_KEY_PATH = "#{Dir.home}/.Mealdbkey"

    # Api interface for mealdb
    # @param key [#to_s] number for your api key
    # @param version [String] choose '1'or '2' to use
    def initialize(key, version)
      # Sets API key and Version
      # Set api_key and check its correct format
      raise 'Version must be 1 or 2' unless %w[1 2].include?(version)

      warn('Warning: API key `1` is only for development') if key.to_s == '1'
      @version = version
      @key = key.to_s
      @api_url = API_ENDPOINT + "/v#{@version}/#{@key}/"
    end

    # Search by name
    # @param name [#to_s]
    # @example #search_meal_name("Arrabiata")
    # @return [Hash] sinle or multiple meals
    def search_meals_name(name)
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/search.php?s=Arrabiata
      url_end = "search.php?s=#{name.to_s.gsub(' ', '%20')}"
      content = api_call(url_end)
      validate(content)
      content
    end

    # Lookup full meal details by id
    # @param id [Integer]
    # @example meal_by_id(52772)
    # @return [Hash] single meal
    def meal_by_id(id)
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/lookup.php?i=52772
      raise "id is not an Integer (#{id.class})" unless id.is_a?(Integer)

      content = api_call("lookup.php?i=#{id}")
      validate(content)
      content
    end

    # Lookup a single random meal
    # @example random_meal
    # @return [Hash] single meal
    def random_meal
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/random.php
      content = api_call('random.php')
      validate(content)
      content
    end

    # Gets List of Categories for meals
    # @example meal_categories
    # @return [Hash] list of meal categories
    def meal_categories
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/list.php?c=list
      content = api_call('list.php?c=list')
      validate(content)
      content
    end

    # Search by primary main ingredient
    # @param primary_ingredient [#to_s]
    # @example #search_by_ingredient("chicken_breast")
    # @example #search_by_ingredient("chicken breast")
    # @return [Hash] one or more meals
    def search_by_ingredient(primary_ingredient)
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?i=chicken_breast
      url_end = "filter.php?i=#{primary_ingredient}"
      content = api_call(url_end)
      validate(content)
      content
    end

    # Return meals by Category
    # @param category [#to_s]
    # @example #meals_by_category("Seafood")
    # @return [Hash] one or more meals
    def meals_by_category(category)
      # API EXAMPLE: https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood
      content = api_call("filter.php?c=#{category}")
      validate(content)
      content
    end

    # Can key/version be saved
    def can_save?
      @key != '1'
    end

    # Saves ApiInterface to a file
    # @param path [string]
    # @raise [RuntimeError] When attempting to safe debug key
    # @Note will overwrite existing file
    def save(path = DEFAULT_KEY_PATH)
      raise 'cannot save debug key' unless can_save?

      File.open(path, 'w') \
      { |file| file.write("version: #{@version}\nkey: #{@key}") }
    end

    # Creates ApiInterface from a file
    # @param path [string]
    # @raise [RuntimeError] When file does not exits or malformed file
    def self.load(path = DEFAULT_KEY_PATH)
      raise "File #{path} does not exist!" unless File.exist?(path)

      raw_data = File.read(path).chomp
      raw_data = raw_data.split
      raise 'Incorrect format for Meal Api Key file' unless raw_data.count == 4
      raise "Error finding version info (#{raw_data[0]})" unless raw_data[0] == 'version:'
      raise "Error finding key info (#{raw_data[2]})" unless raw_data[2] == 'key:'

      new(raw_data[3], raw_data[1])
    end

    private

    # makes api call and returns parsed data
    # On error will retry 3 times
    def api_call(endpoint)
      raise 'endpoint must be string' unless endpoint.is_a?(String)

      url = @api_url.to_s + endpoint.to_s
      safe_url = url.gsub(' ', '%20')
      tries = 3
      begin
        tries -= 1
        res = HTTParty.get(safe_url, timeout: 25, format: :plain)
      rescue Net::OpenTimeout, SocketError
        raise unless tries >= 0

        puts "Failed to reach meal server, Retrying...(#{tries + 1})"
        sleep rand(1..3)
        retry
      end
      raise "Error when calling `#{url}` responce:`#{res.response}`" unless res.success?

      JSON.parse(res, symbolize_names: true)
    end

    # Validate data in expected format and raise exception if not
    def validate(data)
      raise "responce is not in hash (#{data})" unless data.is_a?(Hash)
      raise 'responce missing `:meals` entry' unless data.keys.include?(:meals)
    end
  end
end
