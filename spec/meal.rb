# frozen_string_literal: true

require_relative 'config/environment'

# Partial single
partial_file = File.read('spec/files/partial_meals_one_example.json')
partial_meal_hash = JSON.parse(partial_file, symbolize_names: true)
partial_meal = MealSelector::Meal.new(partial_meal_hash)
partial_meal.whole_meal? # False
partial_meal.to_meal_hash

# Full single
full_file = File.read('spec/files/full_meals_one_example.json')
full_meal_hash = JSON.parse(full_file, symbolize_names: true)
full_meal = MealSelector::Meal.new(full_meal_hash)
full_meal.whole_meal? # True
full_meal.to_meal_hash

# Multiple Full (23)
multiple_full = File.read('spec/files/full_meals_23_example.json')
multiple_full = JSON.parse(multiple_full, symbolize_names: true)
MealSelector::Meal.create_from_array(multiple_full)
MealSelector::Meal.create_from_array(meals: nil)

# Multiple Partial
multiple_part = File.read('spec/files/partial_meals_six_example.json')
multiple_part = JSON.parse(multiple_part, symbolize_names: true)
MealSelector::Meal.create_from_array(multiple_part)

# check ==
full_meal == partial_meal # false
full_meal == full_meal.dup # true

# MEALS::EMPTY_MEALS
MealSelector::Meal::EMPTY_MEALS # {:meals=>nil}
