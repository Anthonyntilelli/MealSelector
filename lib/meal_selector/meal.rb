# frozen_string_literal: true

module MealSelector
  # Data container for a fully looked up Meal (raised Exceptions must be handled by caller)
  class Meal
    # @@favorite = {}
    @@categories = []
    attr_reader :id, :name, :category, :instructions, \
                :type, :ingredient, :youtube

    def initialize(meal_hash)
      # Converts hash into 1 meal object
      # If meal object already exist it will return exiting object
      raise 'meal_hash must be a hash' unless meal_hash.is_a?(Hash)

      raise 'meal_hash is not a hash for a meal' \
            unless meal_hash['idMeal'].is_a?(String)

      @id = meal_hash.delete('idMeal')
      @name = meal_hash.delete('strMeal')
      @category = meal_hash.delete('strCategory') || "Undefined"
      @instructions = meal_hash.delete('strInstructions')
      @type = meal_hash.delete('strTags') || "Undefined"
      @youtube = meal_hash.delete('strYoutube')
      setup_ingredients(meal_hash)

      # Prevent incomplete Meal
      raise "Error setting up instructions" if @instructions.empty? || @instructions.nil?
      raise "Error setting up ingredients" if @ingredient.empty? || @ingredient.nil?
      freeze
    end

    # def add_to_favorites
    #   if @@favorite[self.id].nil?
    #     @@favorite[self.id] = self
    #     true
    #   else
    #     false
    #   end
    # end

    # def self.favorite
    #   @@favorite
    # end

    def self.clear_all
      # @@favorite.clear
      @@categories.clear
    end

    def self.categories_clear
      @@categories.clear
    end

    # def self.favorite_clear
    #   @@favorite.clear
    # end

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

    # def self.save_favorite(path = "#{Dir.home}/.favorite_meals")
    #   if @@favorite.empty? # delete file if exits without favorites
    #     File.delete(path) if File.exist?(path)
    #   else
    #   # Saves favorites to a file (will overwrite existing file)
    #   File.open(path, 'w') { |file| file.write("version: #{@version}\nkey: #{@key}") }
    # end
  
    private

    def setup_ingredients(left_over_meal_hash)
      # Assigns 'strIngredient#' => 'strMeasure#' together
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
