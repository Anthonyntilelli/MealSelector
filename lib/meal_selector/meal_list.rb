# frozen_string_literal: true

module MealSelector
  # List of meals not fully looked up (raised Exceptions must be handled by caller)
  class MealList
    include Enumerable

    def initialize(meal_list)
      raise 'meal_list must be a hash' unless meal_list.is_a?(Hash) 
      raise 'meal_list does not have a `meals` array' unless meal_list['meals'].is_a?(Array)
      raise 'meal_list["meals"] is empty' if meal_list['meals'].empty?
      @list = {}
      meal_list['meals'].each do |partial_meal|
        @list[partial_meal["idMeal"]] = partial_meal["strMeal"]
      end
      @list.freeze
    end

    def each(&block)
      @list.each do |item|
        block.call(item)
      end
    end

    def [](key)
      @list[key]
    end

    def []=(key,assign)
      raise "Not allowed to re-assign variables in MealList"
    end
    
    def count()
      @list.count
    end

    def empty?
      @list.empty?
    end

    def partial?
      # Flag for partial list
      true
    end

  end
end