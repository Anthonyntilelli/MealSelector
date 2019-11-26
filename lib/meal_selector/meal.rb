# frozen_string_literal: true

module MealSelector
  # Data container for a fully looked up Meal (raised Exceptions must be handled by caller)
  class Meal
    @@all = []
    @@favorite = []
    @@categories = []
    attr_reader :id, :name, :category, :instructions, \
                :type, :youtube, :ingredient

    def initialize(meal_hash)
      # Converts hash into 1 meal object
      # If meal object already exist it will return exiting object
      raise 'meal_hash must be a hash' unless meal_hash.is_a?(Hash)

      raise 'meal_hash is not a hash for a meal' \
            unless meal_hash['idMeal'].is_a?(String)

      @id = meal_hash.delete('idMeal')
      existing_meal = @@all.find { |meal| meal.id == @id }
      return existing_meal if !existing_meal.nil?
      @name = meal_hash.delete('strMeal')
      @category = meal_hash.delete('strCategory') || "Undefined"
      @instructions = meal_hash.delete('strInstructions')
      @type = meal_hash.delete('strTags') || "Undefined"
      @youtube = meal_hash.delete('strYoutube')
      setup_ingredients(meal_hash)

      # Prevent incomplete Meal
      raise "Error setting up instructions" if @instructions.empty? || @instructions.nil?
      raise "Error setting up ingredients" if @ingredient.empty? || @ingredient.nil?
      save_and_freeze
    end

    def self.find_by_id(id)
      # Returns meal by id if exists
      # Return nil if it does not exist
      raise 'id must be a string' unless id.is_a?(String)

      @@all.find { |meal| meal.id == id }
    end

    def self.clear_all
      @@all.clear
      @@categories.clear
    end

    def self.categories_clear
      @@categories.clear
    end

    def self.meal_clear
      @@all.clear
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

    def self.all
      @@all
    end

    def self.categories
      @@categories
    end
  
    private

    def save_and_freeze
      # Saves meal to @@all if it does not already exist
      if Meal.find_by_id(id).nil?
        @@all << self
        freeze
        true
      else
        false
      end
    end

    def setup_ingredients(left_over_meal_hash)
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
