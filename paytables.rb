class JacksOrBetterPayTable
  class << self
    def return_multiplier hand_result
      multiplier = 0
      case hand_result
        when :royal_flush
          multiplier = 200
        when :straight_flush
          multiplier = 100
        when :four_of_kind
          multiplier = 50
        when :full_house
          multiplier = 5
        when :flush
          multiplier = 4
        when :straight
          multiplier = 3
        when :three_of_kind
          multiplier = 2
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
          multiplier = 200
        when :royal_flush_with_deuce
          multiplier = 50
        when :four_deuces
          multiplier = 150
        when :five_of_kind
          multipler = 100
        when :straight_flush
          multiplier = 100
        when :four_of_kind
          multiplier = 50
        when :full_house
          multiplier = 5
        when :flush
          multiplier = 4
        when :straight
          multiplier = 3
        when :three_of_kind
          multiplier = 2
        #when :two_pair
        #  multiplier = 2
        #when :pair
        # multiplier = 1
      end
      multiplier
    end
  end
end