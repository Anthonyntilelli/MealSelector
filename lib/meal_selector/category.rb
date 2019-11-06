module MealSelector
    class Category
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
  