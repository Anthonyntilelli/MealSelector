# frozen_string_literal: true

module MealSelector
  # List of meals not fully looked up (raised Exceptions must be handled by caller)
  class MealList
    def initialize(meal_list)
      raise 'meal_list must be a hash' unless meal_list.is_a?(Hash) 
      raise 'meal_list does not have a `meals` array' unless meal_list['meals'].is_a?(Array)
      raise 'meal_list["meals"] is empty' if meal_list['meals'].empty?
      @List = meal_list['meals'].collect do |partial_meal|
        { name: partial_meal["strMeal"], id: partial_meal["idMeal"] }.freeze
      end.sort_by { |hsh| hsh[:name] } 
      @List.freeze
    end

    def [](integer)
      @List[integer]
    end

    def []=(num,assign)
      raise "Not allowed to re-assign variables in MealList"
    end
    
    def count()
      @List.count
    end

  end
end