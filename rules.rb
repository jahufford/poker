class JacksOrBetterScoring
  class << self
    def flush? cards
      suit = cards[0].suit
      if cards.select{|card| card.suit == suit}.length == 5
        puts "Flush"
        return true
      end
      false
    end
    def straight? cards
      sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
      sorted.map!{ |card| card.rank}          
      if sorted[0] == 1 and sorted[1] != 2 # treat ace as one if the next card is 2, otherwise treat as 14
        sorted[0] = 14
        sorted.sort!
      end
      
      straight = true
      sorted.reduce do |a,b|
        if a != (b-1)        
          return false
        end
        b
      end
      puts "Straight"
      true
    end
    
    def straight_flush? cards
      if straight?(cards) and flush?(cards)
        puts "Straight Flush"
        return true
      end
      false
    end
    
    def royal_flush? cards
      sorted = cards.sort{ |card1,card2| card1.rank <=> card2.rank}
      ranks = sorted.map{|card| card.rank}
      sorted[0] = sorted[0].dup # need to dup it so cards doesn't change outside this function
      sorted[0].rank = 14 if sorted[0].rank == 1   
      if (straight_flush? sorted) and (sorted.map{|card|card.rank}.max == 14)
        puts "Royal Flush"
        return true
      end
      false
    end
    
    def pair? cards
      sets = find_sets(cards)   
      if sets.length == 1
        if (sets[0][0] == 2) and ((sets[0][1]>=11) or (sets[0][1]==1)  )# jacks or better      
          puts "pair #{sets[0][1]}'s"
          return true
        end
      end
      false
    end  
    def three_of_kind? cards
      sets = find_sets(cards)   
      if sets.length == 1
        if sets[0][0] == 3      
          puts "three #{sets[0][1]}'s"
          return true
        end
      end
      false
    end
    def four_of_kind? cards
      sets = find_sets(cards) 
      if sets.length == 1
        if sets[0][0] == 4      
          puts "four #{sets[0][1]}'s"
          return true
        end
      end
      false
    end
    def two_pair? cards
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 2
          puts "Two Pair: pair #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end
    def full_house? cards      
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 3
          puts "Full House: three #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end       
    def find_sets cards
      #this function finds the number of multiple of a card ranks in a hand
      # ie, if the hand has 1,1,5,5,7 the return is [[2,1],[2,5]]
      #     if the hand has 5,5,7,7,7 the return is [[2,5],[3,7]]
      #     if the hand has 4,4,4,4,4 the return is [[5,4]]
      #     if the hand has 2,3,8,8,9 the return is [[2,8]]
      sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
      s = "["
      sorted.each{|card| s += "[#{card.rank},#{card.suit}]"}
      s += "]"
      #puts s      
      sets = []
      cnt = 1
      last = sorted.reduce do |a,b|
        if a.rank==b.rank
          cnt += 1
        else        
          sets << [cnt,a.rank] if cnt>1
          cnt = 1
        end
        b
      end
      sets << [cnt,last.rank] if cnt>1    
      sets.sort!{|a,b| a[0]<=>b[0]}
     # puts sets
     # puts "---"
      sets
    end
    def set_test cards
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 3
          puts "Full House: three #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
        else # it's 2 pair
          puts "two pair: pair of #{sets[0][1]}'s and pair of #{sets[1][1]}"
        end
      elsif sets.length == 1
        case sets[0][0]      
        when 4
          puts "four #{sets[0][1]}'s"
        when 3
          puts "three #{sets[0][1]}'s"
        when 2
          puts "pair #{sets[0][1]}'s"
        end
      else
        puts "no sets"
      end
    end
    def score_hand cards
      if royal_flush? cards
        result = :royal_flush
      elsif straight_flush? cards
        result = :straight_flush
      elsif four_of_kind? cards
        result = :four_of_kind
      elsif full_house? cards
        result = :full_house
      elsif flush? cards
        result = :flush
      elsif straight? cards
        result = :straight
      elsif three_of_kind? cards
        result = :three_of_kind
      elsif two_pair? cards
        result = :two_pair
      elsif pair? cards
        result = :pair
      else
        puts "nothing"             
      end
      return result
    end
  end
end

class DeucesWildScoring
  class << self
    def flush? cards
      suit = cards[0].suit
      if cards.select{|card| card.suit == suit}.length == 5
        puts "Flush"
        return true
      end
      false
    end
    def straight? cards
      sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
      sorted.map!{ |card| card.rank}          
      if sorted[0] == 1 and sorted[1] != 2 # treat ace as one if the next card is 2, otherwise treat as 14
        sorted[0] = 14
        sorted.sort!
      end
      
      straight = true
      sorted.reduce do |a,b|
        if a != (b-1)        
          return false
        end
        b
      end
      puts "Straight"
      true
    end
    
    def straight_flush? cards
      if straight?(cards) and flush?(cards)
        puts "Straight Flush"
        return true
      end
      false
    end
    
    def royal_flush? cards
      sorted = cards.sort{ |card1,card2| card1.rank <=> card2.rank}
      ranks = sorted.map{|card| card.rank}
      sorted[0] = sorted[0].dup # need to dup it so cards doesn't change outside this function
      sorted[0].rank = 14 if sorted[0].rank == 1   
      if (straight_flush? sorted) and (sorted.map{|card|card.rank}.max == 14)
        puts "Royal Flush"
        return true
      end
      false
    end
    
    def pair? cards
      sets = find_sets(cards)   
      if sets.length == 1
        if (sets[0][0] == 2) and ((sets[0][1]>=11) or (sets[0][1]==1)  )# jacks or better      
          puts "pair #{sets[0][1]}'s"
          return true
        end
      end
      false
    end  
    def three_of_kind? cards
      sets = find_sets(cards)   
      if sets.length == 1
        if sets[0][0] == 3      
          puts "three #{sets[0][1]}'s"
          return true
        end
      end
      false
    end
    def four_of_kind? cards
      sets = find_sets(cards) 
      if sets.length == 1
        if sets[0][0] == 4      
          puts "four #{sets[0][1]}'s"
          return true
        end
      end
      false
    end
    def two_pair? cards
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 2
          puts "Two Pair: pair #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end
    def full_house? cards      
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 3
          puts "Full House: three #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end       
    def find_sets cards
      #this function finds the number of multiple of a card ranks in a hand
      # ie, if the hand has 1,1,5,5,7 the return is [[2,1],[2,5]]
      #     if the hand has 5,5,7,7,7 the return is [[2,5],[3,7]]
      #     if the hand has 4,4,4,4,4 the return is [[5,4]]
      #     if the hand has 2,3,8,8,9 the return is [[2,8]]
      sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
      s = "["
      sorted.each{|card| s += "[#{card.rank},#{card.suit}]"}
      s += "]"
      #puts s      
      sets = []
      cnt = 1
      last = sorted.reduce do |a,b|
        if a.rank==b.rank
          cnt += 1
        else        
          sets << [cnt,a.rank] if cnt>1
          cnt = 1
        end
        b
      end
      sets << [cnt,last.rank] if cnt>1    
      sets.sort!{|a,b| a[0]<=>b[0]}
     # puts sets
     # puts "---"
      sets
    end
    def set_test cards
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 3
          puts "Full House: three #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
        else # it's 2 pair
          puts "two pair: pair of #{sets[0][1]}'s and pair of #{sets[1][1]}"
        end
      elsif sets.length == 1
        case sets[0][0]      
        when 4
          puts "four #{sets[0][1]}'s"
        when 3
          puts "three #{sets[0][1]}'s"
        when 2
          puts "pair #{sets[0][1]}'s"
        end
      else
        puts "no sets"
      end
    end
    def score_hand cards
      if royal_flush? cards
        result = :royal_flush
      elsif straight_flush? cards
        result = :straight_flush
      elsif four_of_kind? cards
        result = :four_of_kind
      elsif full_house? cards
        result = :full_house
      elsif flush? cards
        result = :flush
      elsif straight? cards
        result = :straight
      elsif three_of_kind? cards
        result = :three_of_kind
      elsif two_pair? cards
        result = :two_pair
      elsif pair? cards
        result = :pair
      else
        puts "nothing"             
      end
      return result
    end
  end
end