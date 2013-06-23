# class JacksOrBetterPayTable
  # class << self
    # def return_multiplier hand_result
      # multiplier = 0
      # case hand_result
        # when :royal_flush
          # multiplier = 250
        # when :straight_flush
          # multiplier = 50
        # when :four_of_kind
          # multiplier = 25
        # when :full_house
          # multiplier = 9
        # when :flush
          # multiplier = 6
        # when :straight
          # multiplier = 4
        # when :three_of_kind
          # multiplier = 3
        # when :two_pair
          # multiplier = 2
        # when :pair
          # multiplier = 1
      # end
      # multiplier
    # end
  # end
# end

# class DeucesWildPayTable
  # class << self
    # def return_multiplier hand_result
      # multiplier = 0
      # case hand_result
        # when :royal_flush
          # multiplier = 940        
        # when :four_deuces
          # multiplier = 400
        # when :wild_royal_flush
          # multiplier = 25
        # when :five_of_kind
          # multipler = 16
        # when :straight_flush
          # multiplier = 13
        # when :four_of_kind
          # multiplier = 4
        # when :full_house
          # multiplier = 3
        # when :flush
          # multiplier = 2
        # when :straight
          # multiplier = 2
        # when :three_of_kind
          # multiplier = 1
        # #when :two_pair
        # #  multiplier = 2
        # #when :pair
        # # multiplier = 1
      # end
      # multiplier
    # end
  # end
# end

class JacksOrBetterPayTable
  def initialize
    @multiples = { royal_flush:250,
                   straight_flush:50,
                   four_of_kind:25,
                   full_house:9,
                   flush:6,
                   straight:4,
                   three_of_kind:3,
                   two_pair:2,
                   pair:1
                 }
  end
  def return_multiplier hand_result
    return @multiples[hand_result] if @multiples.key? hand_result
    return 0
  end
end

class DeucesWildPayTable
  def initialize
    @multiples = { royal_flush:940,        
                   four_deuces:400,
                   wild_royal_flush:25,
                   five_of_kind:16,
                   straight_flush:13,
                   four_of_kind:4,
                   full_house:3,
                   flush:2,
                   straight:2,
                   three_of_kind:1
                 }
  end  
  def return_multiplier hand_result
    return @multiples[hand_result] if @multiples.key? hand_result
    return 0
  end
end

class CustomPayTable  
  def return_multiplier hand_result
    multiplier = 0
    case hand_result
      when :royal_flush
        multiplier = 940        
      when :four_deuces
        multiplier = 400
      when :wild_royal_flush
        multiplier = 25
      when :five_of_kind
        multipler = 16
      when :straight_flush
        multiplier = 13
      when :four_of_kind
        multiplier = 4
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