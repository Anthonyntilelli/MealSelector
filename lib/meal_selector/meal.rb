# frozen_string_literal: true

module MealSelector
  # Data container for a fully looked up Meal (raised Exceptions must be handled by caller)
  class Meal
    @@favorites = {}
    @@categories = []
    attr_reader :id, :name, :category, :instructions, \
                :type, :ingredient, :youtube

    def initialize(meal)
      # Converts hash into 1 meal object
      # If meal object already exist it will return exiting object
      meal_hash = meal.dup
      raise "meal must be a hash, instead #{meal_hash.class}" unless meal_hash.is_a?(Hash)

      raise 'meal is not a hash for a meal' \
            unless meal_hash['idMeal'].is_a?(String)

      raise 'Incorrect hash for meal object' \
            unless meal_hash['meals'].nil?

      @id = meal_hash.delete('idMeal')
      @name = meal_hash.delete('strMeal')
      @category = meal_hash.delete('strCategory') || "Undefined"
      @instructions = meal_hash.delete('strInstructions')
      @type = meal_hash.delete('strTags') || "Undefined"
      @youtube = meal_hash.delete('strYoutube')
      if meal_hash["sync_ingredients"].nil?
        setup_ingredients(meal_hash)
      else
        # load from saved meal
        raise "sync_ingredients is not a hash" unless meal_hash["sync_ingredients"].is_a?(Hash)
        @ingredient = meal_hash.delete('sync_ingredients')
      end

      # Prevent incomplete Meal
      raise "Error setting up instructions" if @instructions.empty? || @instructions.nil?
      raise "Error setting up ingredients" if @ingredient.empty? || @ingredient.nil?
      freeze
    end

    def add_to_favorites
      if @@favorites[self.id].nil?
        @@favorites[self.id] = self
        true
      else
        false
      end
    end

    def to_meal_hash
      # turns object back into a meal hash
      {
        'idMeal' => @id,
        'strMeal' => @name,
        'strCategory' => @category,
        'strInstructions' => @instructions,
        'strTags' => @type,
        'strYoutube' => @youtube,
        'sync_ingredients' => @ingredient
      }
    end

    # Class Methods

    def self.favorites
      @@favorites
    end

    def self.clear_all
      @@favorites.clear
      @@categories.clear
    end

    def self.categories_clear
      @@categories.clear
    end

    def self.favorites_clear
      @@favorites.clear
    end

    def self.create_from_array(meals_hash)
      # Create new meals from array of meals and returns array of Meal objects
      raise 'meals_hash must me a hash' unless meals_hash.is_a?(Hash)

      raise 'meals_hash must be an array of meals' \
            unless meals_hash['meals'].is_a?(Array)

      meals_hash['meals'].collect { |meal| Meal.new(meal) }
    end

    def self.set_categories(categories_arr)
      # sets a list of meal categories by Api_interface
      raise 'categories_arr must be an Array' unless categories_arr.is_a?(Array)
      raise 'categories must not be empty' if  categories_arr.empty?

      main_count = categories_arr.count
      processed_categories = categories_arr.collect { |cat| cat["strCategory"] }.compact
      # check for nil categories
      raise "Count Error in categories" if main_count != processed_categories.count
      @@categories = processed_categories
    end

    def self.categories
      @@categories
    end

    def self.save_favorite(path = "#{Dir.home}/favorite_meals.json")
      # Saves favorites to a file (will overwrite existing file)
      converted = @@favorites.collect { |id, meal| meal.to_meal_hash }
      meal_hash = { 'meals' => converted }
      File.open(path, 'w') { |file| file.write(meal_hash.to_json) }
    end

    def self.load_favorites(path = "#{Dir.home}/favorite_meals.json")
      # Loads saved favorite meals and adds to favorites
      return false unless File.exist?(path)
      raw_data = File.read(path).chomp
      parsed = JSON.parse(raw_data)
      meals_arr = create_from_array(parsed)
      meals_arr.each { |meal|  meal.add_to_favorites }
      true
    end

    private

    def setup_ingredients(left_over_meal_hash)
      # Assigns 'strIngredient#' and 'strMeasure#' together
      @ingredient = {} # 'strIngredient#' => 'strMeasure#'
      left_over_meal_hash.each do |key, value|
        next if value == '' || value == ' ' || value.nil? # prevent blank entries
        next if key == '' || key == ' ' || key.nil? # prevent blank entries

        case key
        when /strIngredient.+/
          location = key.gsub('strIngredient', '')
          @ingredient[value] = left_over_meal_hash['strMeasure' + location.to_s]
        end
      end
      @ingredient = @ingredient.compact
    end
  end
end
