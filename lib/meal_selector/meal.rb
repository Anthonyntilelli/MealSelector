module MealSelector
    class Meal
        # Data container for meals
        # All raised Exceptions are handled by caller
        @@all = []
        attr_reader :id, :name, :category, :instructions, :type, :youtube, :ingredient

        def initialize(meal_hash)
            # Converts hash in a meal object
            raise "meal_hash must be a hash" unless meal_hash.is_a?(Hash)
            raise "meal_hash is not a hash for a meal" unless meal_hash['idMeal'].is_a?(String)
            @ingredient = {}
            meal_hash.each do |key, value|
                if value != "" && value != " "  # prevent blank entries
                    case key
                    when "idMeal"
                        @id = value
                    when "strMeal"
                        @name = value
                    when "strCategory"
                        @category = value
                    when "strInstructions"
                        @instructions = value
                    when "strTags"
                        @type = value
                    when "strYoutube"
                        @youtube = value
                    when /strIngredient.+/
                        # "strIngredient#" => "strMeasure#"
                        location = key.gsub("strIngredient", "")
                        @ingredient[value] = meal_hash["strMeasure" + "#{location}"]
                    end
                end
            end
            self.save_and_freeze
        end

        def self.meal_by_id(id)
            # Returns meal by id if exists
            # Return nil if it does not exist
            raise "ID must be a string" unless id.is_a?(String)
            @@all.find { |meal| meal.id == id }
        end

        def self.all
            @@all
        end

        def self.clear
            @@all.clear
        end

        private 
        def save_and_freeze
            # Saves meal to @@all if it does not already exist
            if Meal.meal_by_id(self.id).nil?
                @@all << self
                self.freeze
                true
            else
                false
            end
        end
    end
end
