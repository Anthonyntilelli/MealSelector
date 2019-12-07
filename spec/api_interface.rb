# frozen_string_literal: true

require_relative 'config/environment'
# api = MealSelector::ApiInterface.new('1','2')
api = MealSelector::ApiInterface.load

# results
api.search_meals_name('chicken')
# no results
api.search_meals_name('wedwdwd')

# results
api.meal_by_id(52_772)
# no results
api.meal_by_id(-1)

# results
api.random_meal

# results
api.meal_categories

# results
a = api.search_by_ingredient('chicken_breast')
b = api.search_by_ingredient('chicken breast')
puts a == b
# no results
api.search_by_ingredient('djahwjkdhall')

# results
c = api.meals_by_category('seafood')
d = api.meals_by_category('seAFoOd')
e = api.meals_by_category('Seafood')
puts c == d
puts e == d
# no results
api.meals_by_category('fljkhekfdheflekfle')

# expect raise error
standard = MealSelector::ApiInterface.new('1', '2')
standard.save("/tmp/key_#{rand(0..99)}")
