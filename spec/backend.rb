# frozen_string_literal: true
require_relative 'config/environment'

# Initial
backend = MealSelector::Backend.new(MealSelector::ApiInterface.load)
backend.categories
backend.favorites

# random_meal
backend.find_random_meal

# favorites
MealSelector::Backend::DEFAULT_FAVORITES_PATH
backend.favorites_changed?  # False
meal = backend.find_random_meal
backend.add_to_favorites(meal)
backend.add_to_favorites("Q")
backend.favorites_changed?  # True
backend.favorites

# find_meal_by_name
backend.find_meals_by_name("Arrabiata")
backend.find_meals_by_name("chicken")

# find_meals_by_categories
a = backend.find_meals_by_categories("Seafood")
backend.find_meals_by_categories("jhsdfksdjfhs") # raises
b = backend.find_meals_by_categories("sEaFoOd")
a == b # True

# find_meal_by_ingredient
c = backend.find_meal_by_ingredient("chicken breast")
d = backend.find_meal_by_ingredient("chicken breast")
backend.find_meal_by_ingredient("sdkjasdklaj sdlkasjdlka")
c == d

# find_meal_by_id
backend.find_meal_by_id(52772)

# load/save
backend.save_favorites
backend.load_favorites
