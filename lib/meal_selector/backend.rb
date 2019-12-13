# frozen_string_literal: true

module MealSelector
  # Management layer between ApiInterface and Meal Object
  class Backend
    DEFAULT_FAVORITES_PATH = "#{Dir.home}/favorite_meals.json"

    attr_reader :favorites, :categories
    def initialize(api)
      # Sets up favorites and categories via api
      # key at `nil` will cause backend to look for file
      raise 'api must be a api_interface' unless api.is_a?(ApiInterface)

      @favorites = {}
      @categories = {}
      @favorite_state = nil
      @api = api
      @categories = populate_categories(@api.meal_categories)
      load_favorites
      favorites_init
    end

    def save_api_info
      #saves keys and version to default file
      @interface.save
    end

    # Favorites
    def add_to_favorites(meal)
      raise 'Not a meal' unless meal.is_a?(Meal)

      if @favorites[meal.id].nil?
        @favorites[meal.id] = meal
        true
      else
        false
      end
    end

    def save_favorites(path = DEFAULT_FAVORITES_PATH)
      # Saves favorites to a file (will overwrite existing file)
      converted = @favorites.collect { |_id, meal| meal.to_meal_hash }
      meal_hash = { meals: converted }
      File.open(path, 'w') { |file| file.write(meal_hash.to_json) }
    end

    def load_favorites(path = DEFAULT_FAVORITES_PATH)
      # Loads saved favorite meals and adds to favorites
      return false unless File.exist?(path)
      raise "#{path} is not a file" unless File.file?(path)

      raw_data = File.read(path).chomp
      parsed = JSON.parse(raw_data, symbolize_names: true)
      meals_hsh = Meal.create_from_array(parsed)
      meals_hsh.each { |_key, meal| add_to_favorites(meal) }
      true
    end

    def favorites_init
      # sets the favoriate state to watch
      @favorite_state = @favorites.keys.sort
    end

    def favorites_changed?
      # returns true if favorites change since
      # favorite_init was called
      @favorite_state != @favorites.keys.sort
    end

    def clear_favorites
      # clears favorites
      # favorites are change if not originally empty
      @favorites.clear
    end

    def find_meals_by_name(name)
      # Returns one or more meals by name
      Meal.create_from_array(@api.search_meals_name(name))
    end

    def find_meals_by_categories(category)
      # Returns list of meals based on a category
      raise '@categories is empty' if @categories.empty?
      raise 'Provided category is not valid' unless @categories.include?(category.capitalize)

      meals = @api.meals_by_category(category)
      Meal.create_from_array(meals)
    end

    def find_meal_by_ingredient(primary_ingredient)
      # Outputs a meals based on ingredient
      meals_hsh = @api.search_by_ingredient(primary_ingredient.downcase)
      Meal.create_from_array(meals_hsh)
    end

    def find_random_meal
      # Provides a random meal object
      Meal.new(@api.random_meal)
    end

    def find_meal_by_id(id)
      # returns meal by id
      Meal.new(@api.meal_by_id(id))
    end

    private

    def populate_categories(category_hsh)
      # Converts to categories array
      raise 'Incorrect category_hash' if category_hsh[:meals].nil?

      category_hsh[:meals].collect { |cat| cat[:strCategory] }
    end
  end
end
