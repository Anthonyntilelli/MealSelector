# frozen_string_literal: true

module MealSelector
  # Data container for meals (raised Exceptions must be handled by caller)
  class Meal
    @@all = []
    attr_reader :id, :name, :category, :instructions, \
                :type, :youtube, :ingredient

    def initialize(meal_hash)
      # Converts hash into 1 meal object
      raise 'meal_hash must be a hash' unless meal_hash.is_a?(Hash)

      raise 'meal_hash is not a hash for a meal' \
            unless meal_hash['idMeal'].is_a?(String)

      @id = meal_hash.delete('idMeal')
      existing_meal = @@all.find { |meal| meal.id == @id }
      return existing_meal if !existing_meal.nil?
      @name = meal_hash.delete('strMeal')
      @category = meal_hash.delete('strCategory')
      @instructions = meal_hash.delete('strInstructions')
      @type = meal_hash.delete('strTags')
      @youtube = meal_hash.delete('strYoutube')
      setup_ingredients(meal_hash)
      save_and_freeze
    end

    def self.find_by_id(id)
      # Returns meal by id if exists
      # Return nil if it does not exist
      raise 'id must be a string' unless id.is_a?(String)

      @@all.find { |meal| meal.id == id }
    end

    def self.all
      @@all
    end

    def self.clear
      @@all.clear
    end

    def self.create_from_array(meals_hash)
      # Create new meals from array of meals and returns array of Meal objects
      raise 'meals_hash must me a hash' unless meals_hash.is_a?(Hash)

      raise 'meals_hash must be an array of meals' \
            unless meal_hash['meals'].is_a?(Array)

      meal_hash['meals'].collect { |meal| Meal.new(meal) }
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
        next if value == '' && value == ' ' # prevent blank entries

        case key
        when /strIngredient.+/
          location = key.gsub('strIngredient', '')
          @ingredient[value] = left_over_meal_hash['strMeasure' + location.to_s]
        end
      end
    end
  end
end
