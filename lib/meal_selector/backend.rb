# frozen_string_literal: true

module MealSelector
  # Management layer between ApiInterface and Meal Object
  # @raise network issue can raise exceptions
  # @author Anthony Tilelli
  class Backend
    # Default location for favorite meals to be saved
    DEFAULT_FAVORITES_PATH = "#{Dir.home}/favorite_meals.json"

    attr_reader :favorites, :categories

    # Sets up favorites and categories via api
    # @param api [ApiInterface]
    def initialize(api)
      raise 'api must be a api_interface' unless api.is_a?(ApiInterface)

      @favorites = {}
      @categories = {}
      @favorite_state = :unset
      @api = api
      @categories = populate_categories(@api.meal_categories)
      load_favorites
      favorites_init
    end

    # Can api key/version be saved?
    # return [Boolean]
    def api_can_save?
      @api.can_save?
    end

    # Saves keys and version to default file
    # @note will overwrite existing file
    # @return [boolean] If was save to file
    def save_api_info
      if api_can_save?
        @api.save
        return true
      end
      false
    end

    # Favorites
    # Adds meal to favorites
    # @param meal [Meal]
    # @return [boolean] If meal was added
    def add_to_favorites(meal)
      raise 'Not a meal' unless meal.is_a?(Meal)

      if @favorites[meal.id].nil?
        @favorites[meal.id] = meal
        true
      else
        false
      end
    end

    # Saves favorites to a file
    # @note Will overwrite existing file
    # @return [void]
    def save_favorites(path = DEFAULT_FAVORITES_PATH)
      converted = @favorites.collect { |_id, meal| meal.to_meal_hash }
      meal_hash = { meals: converted }
      File.open(path, 'w') { |file| file.write(meal_hash.to_json) }
    end

    # Loads saved favorite meals from path and adds to favorites
    # @param path [String]
    # @return [Boolean] If file was loaded
    # @raise If path is not a file
    def load_favorites(path = DEFAULT_FAVORITES_PATH)
      return false unless File.exist?(path)
      raise "#{path} is not a file" unless File.file?(path)

      raw_data = File.read(path).chomp
      parsed = JSON.parse(raw_data, symbolize_names: true)
      meals_hsh = Meal.create_from_array(parsed)
      meals_hsh.each { |_key, meal| add_to_favorites(meal) }
      true
    end

    # Sets the favorites state to watch for changes
    # @return [void]
    def favorites_init
      @favorite_state = @favorites.keys.sort
    end

    # True if favorites change since `#favorite_init` was called
    # @return [Boolean]
    # @raise If `#favorites_changed?` is called before `#favorite_init`
    def favorites_changed?
      raise 'favorite_init has not yet been called' if @favorite_state == :unset

      @favorite_state != @favorites.keys.sort
    end

    # Clears favorites
    # @return [void]
    def clear_favorites
      @favorites.clear
    end

    # Meal actions

    # Find meals by name
    # @param name [#to_s]
    # @return [Hash] zero (`{}`) or more meals
    def find_meals_by_name(name)
      Meal.create_from_array(@api.search_meals_name(name))
    end

    # find meals based on a category
    # @param category [String]
    # @raise if category is not in @categories
    # @return [Hash] zero (`{}`) or more meals
    def find_meals_by_categories(category)
      raise '@categories is empty' if @categories.empty?
      raise 'category must be a string' unless category.is_a?(String)
      raise 'Provided category is not valid' unless @categories.include?(category.capitalize)

      meals = @api.meals_by_category(category)
      Meal.create_from_array(meals)
    end

    # Finds meals based on primary ingredient
    # @param primary_ingredient [String]
    # @return [Hash] hash of zero (`{}`) or more meals
    def find_meal_by_ingredient(primary_ingredient)
      meals_hsh = @api.search_by_ingredient(primary_ingredient.downcase)
      Meal.create_from_array(meals_hsh)
    end

    # Finds random meal object
    # @return [Meal] single meal
    def find_random_meal
      Meal.new(@api.random_meal)
    end

    # Creates a whole meal if a meal is not.
    # @param meal [Meal]
    # @return [Meal] whole meal
    def resolve_meal(meal)
      raise 'Must be a meal object' unless meal.is_a?(Meal)

      resolved =  if meal.whole_meal?
                    meal
                  else
                    # returns meal by id
                    Meal.new(@api.meal_by_id(meal.id.to_i))
                  end
      resolved
    end

    private

    # Converts to categories array
    def populate_categories(category_hsh)
      raise 'Incorrect category_hash' if category_hsh[:meals].nil?

      category_hsh[:meals].collect { |cat| cat[:strCategory] }
    end
  end
end
