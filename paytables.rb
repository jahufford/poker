class JacksOrBetterPayTable
  class << self
    def return_multiplier hand_result
      multiplier = 0
      case hand_result
        when :royal_flush
          multiplier = 250
        when :straight_flush
          multiplier = 50
        when :four_of_kind
          multiplier = 25
        when :full_house
          multiplier = 9
        when :flush
          multiplier = 6
        when :straight
          multiplier = 4
        when :three_of_kind
          multiplier = 3
        when :two_pair
          multiplier = 2
        when :pair
          multiplier = 1
      end
      multiplier
    end
  end
end

class DeucesWildPayTable
  class << self
    def return_multiplier hand_result
      multiplier = 0
      case hand_result
        when :royal_flush
          multiplier = 300        
        when :four_deuces
          multiplier = 200
        when :wild_royal_flush
          multiplier = 25
        when :five_of_kind
          multipler = 15
        when :straight_flush
          multiplier = 9
        when :four_of_kind
          multiplier = 5
        when :full_house
          multiplier = 3
        when :flush
          multiplier = 2
        when :straight
          multiplier = 2
        when :three_of_kind
          multiplier = 1
        #when :two_pair
        #  multiplier = 2
        #when :pair
        # multiplier = 1
      end
      multiplier
    end
  end
end