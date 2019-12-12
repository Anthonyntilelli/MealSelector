# frozen_string_literal: true

module MealSelector
  # Data container for a fully looked up Meal
  # Raised Exceptions must be handled by caller
  class Meal
    EMPTY_MEALS = { meals: nil }.freeze

    attr_reader :id, :name, :category, :instructions, \
                :type, :ingredient, :youtube
    def initialize(meal_hash)
      # Converts hash into 1 meal object
      pre_meal = init_check(meal_hash)
      raise 'meal lacks an id' unless pre_meal[:idMeal].is_a?(String)
      raise 'meal_hash lacks a name' unless pre_meal[:strMeal].is_a?(String)

      @id = pre_meal.delete(:idMeal)
      @name = pre_meal.delete(:strMeal)
      @whole_meal = pre_meal.keys.include?(:strInstructions)
      whole_meal_init(pre_meal) if whole_meal?
      freeze
    end

    def to_meal_hash
      # turns object back into a meal hash
      if whole_meal?
        {
          idMeal: @id,
          strMeal: @name,
          strCategory: @category,
          strInstructions: @instructions,
          strTags: @type,
          strYoutube: @youtube,
          sync_ingredients: @ingredient
        }
      else
        { idMeal: @id, strMeal: @name }
      end
    end

    def whole_meal?
      @whole_meal
    end

    def ==(other)
      # compare meal objects
      return false unless other.is_a?(Meal)
      return false if other.whole_meal? != whole_meal?

      a = to_meal_hash
      b = other.to_meal_hash
      a == b
    end

    def self.create_from_array(meals_hash)
      # Create new meals from array of meals and returns hash of Meal objects
      raise 'meals_hash must me a hash' unless meals_hash.is_a?(Hash)
      return {} if meals_hash == EMPTY_MEALS
      raise 'meals_hash must be an array of meals' unless meals_hash[:meals].is_a?(Array)

      processed = {}
      meals_hash[:meals].each do |meal|
        meal_obj = Meal.new(meals: [meal])
        processed[meal_obj.id.to_sym] = meal_obj
      end
      processed
    end

    private

    def setup_ingredients(left_over_meal_hash)
      # Assigns :strIngredient# and :strMeasure# together
      @ingredient = {}
      left_over_meal_hash.each do |key, value|
        next if value == '' || value == ' ' || value.nil? # prevent blank entries

        case key
        when /strIngredient.+/
          location = key.to_s.gsub('strIngredient', '')
          measure = 'strMeasure' + location.to_s
          @ingredient[value] = left_over_meal_hash[measure.to_sym]
        end
      end
      @ingredient.compact!
    end

    def whole_meal_init(full_hash)
      # Inits part of meal obj for whole meal
      @category = full_hash.delete(:strCategory) || 'Undefined'
      @instructions = full_hash.delete(:strInstructions)
      @type = full_hash.delete(:strTags) || 'Undefined'
      @youtube = full_hash.delete(:strYoutube)
      if full_hash[:sync_ingredients].nil?
        # load from API meal
        setup_ingredients(full_hash.compact!)
      else
        # Saved meal
        raise ':sync_ingredients is not a hash' unless full_hash[:sync_ingredients].is_a?(Hash)

        @ingredient = full_hash.delete(:sync_ingredients)
      end
    end

    def init_check(meal_hash)
      # checks meal hash and returns meal
      raise 'meal_hash must be a hash' unless meal_hash.is_a?(Hash)
      raise 'Empty Meal provided' if meal_hash == EMPTY_MEALS
      raise 'Incorrect hash for meal object' unless meal_hash[:meals].is_a?(Array)
      raise 'More then one meal provided' unless meal_hash[:meals].count == 1

      meal_hash[:meals][0].dup
    end
  end
end
