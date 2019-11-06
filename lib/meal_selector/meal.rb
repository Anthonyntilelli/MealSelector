module MealSelector
    class Meal
        # Data container for meals
        @@all = []

        def self.all
            @@all
        end

        def save
            @@all << self
        end
    end
end
  