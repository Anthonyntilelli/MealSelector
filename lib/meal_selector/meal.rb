# frozen_string_literal: true

module MealSelector
  # Data container for a partial/whole Meal
  # @note check #whole_meal? before looking beyond meal name and id.
  # @author Anthony Tilelli
  class Meal
    # Empty meals are invalid
    EMPTY_MEALS = { meals: nil }.freeze

    attr_reader :id, :name, :category, :instructions, \
                :type, :ingredient, :youtube

    # Creates a single meal_hash into a frozen Meal.
    # @param meal_hash [Hash] must contain one meal in meal format `{ meals: [meal] }`
    def initialize(meal_hash)
      raise 'meal_hash must be a hash' unless meal_hash.is_a?(Hash)
      raise 'Empty Meal provided' if meal_hash == EMPTY_MEALS
      raise 'Incorrect hash for meal object' unless meal_hash[:meals].is_a?(Array)
      raise 'More then one meal provided' unless meal_hash[:meals].count == 1

      pre_meal = meal_hash[:meals][0].dup
      raise 'meal lacks an id' unless pre_meal[:idMeal].is_a?(String)
      raise 'meal_hash lacks a name' unless pre_meal[:strMeal].is_a?(String)

      # minimum meal_data
      @id = pre_meal.delete(:idMeal)
      @name = pre_meal.delete(:strMeal)
      @whole_meal = pre_meal.keys.include?(:strInstructions)
      # Rest of meal data
      whole_meal_init(pre_meal) if whole_meal?
      freeze
    end

    # Does meal object contain enough infor for show meal?
    # @return [Boolean] if meal contains more then :id and :name.
    def whole_meal?
      @whole_meal
    end

    # Turns object back into a meal found in the `meals: array`. Usefull for saving to a file.
    # @return [Hash]
    def to_meal_hash
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

    # Compares if two meal objects are equal
    # @param other [Meal]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(Meal)
      return false if other.whole_meal? != whole_meal?

      a = to_meal_hash
      b = other.to_meal_hash
      a == b
    end

    # Create new meals from multiple meals and returns hash of Meal objects
    # @param meals_hash [Hash] contain multiple meals in meals format `{ meals: [meal] }`
    # @returns [Hash] Meals hashed by id `{id => Meal}`
    def self.create_from_array(meals_hash)
      raise 'meals_hash must me a hash' unless meals_hash.is_a?(Hash)
      return {} if meals_hash == EMPTY_MEALS
      raise 'meals_hash must be an array of meals' unless meals_hash[:meals].is_a?(Array)

      processed = {}
      meals_hash[:meals].each do |meal|
        next if meal[:strMeal].match?(/test/)

        meal_obj = Meal.new(meals: [meal])
        processed[meal_obj.id.to_sym] = meal_obj
      end
      processed
    end

    private

    # Combines :strIngredient# and :strMeasure# together for init
    def setup_ingredients(left_over_meal_hash)
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

    # Sets values for whole meal for init
    def whole_meal_init(full_hash)
      @category = full_hash.delete(:strCategory) || 'Undefined'
      @instructions = full_hash.delete(:strInstructions) || 'Not provided'
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
      @ingredient.freeze
    end
  end
end
