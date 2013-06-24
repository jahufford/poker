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
        #sorted[0] = sorted[0].dup # dup it so it doesn't change cards outside this func
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
    def royal_flush? cards # natural royal flush
      sorted = cards.sort{ |card1,card2| card1.rank <=> card2.rank}
      ranks = sorted.map{|card| card.rank}
      sorted[0] = sorted[0].dup # need to dup it so cards doesn't change outside this function
      sorted[0].rank = 14 if sorted[0].rank == 1   
      if (straight_flush? sorted)
        if(sorted.map{|card|card.rank}.max == 14) and sorted.select{|card| card.rank ==2}.empty? 
        # puts "Royal Flush"
          return true
        end
      end
      false
    end
    def four_deuces? cards
      if cards.count{|card| card.rank==2} == 4
        return true
      end
      false
    end
    def wild_royal_flush? cards
      sorted = cards.sort{ |card1,card2| card1.rank <=> card2.rank}
      ranks = sorted.map{|card| card.rank}
      sorted[0] = sorted[0].dup # need to dup it so cards doesn't change outside this function
      sorted[0].rank = 14 if sorted[0].rank == 1   
      if (straight_flush? sorted)
        max_card = sorted.map{|card| card.rank}.max
        deuce_num = sorted.select{|card| card.rank==2}.length
        if max_card >= 14-deuce_num
        # puts "Royal Flush"
          return true
        end
      end
      false
    end
    def five_of_kind? cards
      sets = find_sets(cards)
      if sets.length == 1 # set would only be a one, since a full house would be picked up earlier
        if sets[0][0] == 5      
         # puts "1three #{sets[0][1]}'s"
          return true        
        end    
      end
      false
    end    
    def straight_flush? cards
      if straight?(cards) and flush?(cards)
       # puts "Straight Flush"
        return true
      end
      false
    end
    def four_of_kind? cards
      sets = find_sets(cards) 
      if sets.length == 1
        if sets[0][0] == 4      
         # puts "four #{sets[0][1]}'s"
          return true
        end
      end
      false
    end
    def full_house? cards      
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 3
         # puts "Full House: three #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end
    def flush? cards
      wilds, regulars = cards.partition{|card| card.rank ==2}      
      suit = regulars[0].suit      
      if regulars.select{|card| card.suit == suit}.length == (regulars.length)
       # puts "Flush"
        return true
      end
      false
    end
    def straight? cards
      sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
      sorted.map!{ |card| card.rank}      
            
      wilds, regulars = sorted.partition{|rank| rank==2} # split hand into wild cards and regulars
      # use 3 below instead of 2, since 2's are wild
      if regulars[0] == 1 and regulars[1] != 2+wilds.length # treat ace as one if the next card is 2, but account for the wilds        
        regulars[0] = 14
        regulars.sort!
      end      
      
      wild_cnt = wilds.length
      straight = true     
      regulars.reduce do |a,b|
        if a != (b-1) # use b-1, because 7-5 =2 but there's 1 card in between, so (7-1) - 5 = 1
          if ((b-1)>a) and ((b-1)-a <= wild_cnt)
            wild_cnt -= (b-1)-a
          else
            return false
          end
        end
        b
      end
      #puts "Straight"
      true
    end
    def three_of_kind? cards
      sets = find_sets(cards)
      if sets.length == 1 # set would only be a one, since a full house would be picked up earlier
        if sets[0][0] == 3      
         # puts "1three #{sets[0][1]}'s"
          return true        
        end    
      end
      false
    end
    def two_pair? cards #probably not needed
      sets = find_sets(cards)   
      if sets.length == 2
        if sets[0][0] == 2 and sets[1][0] == 2
          #puts "Two Pair: pair #{sets[1][1]}'s and pair of #{sets[0][1]}'s"
          return true
        end
      end
    end
    def pair? cards # probably not needed
      sets = find_sets(cards)   
      if sets.length == 1
        if (sets[0][0] == 2) and ((sets[0][1]>=11) or (sets[0][1]==1)  )# jacks or better      
         # puts "pair #{sets[0][1]}'s"
          return true
        end
      end
      false
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
      wilds, regulars = cards.partition{|card| card.rank == 2}      
      sets = []
      cnt = 1
      last = regulars.sort{|a,b| a.rank<=>b.rank}.reduce do |a,b|
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
      # if no sets found, pick highest rank to add wild cards to
      if sets.empty? and wilds.length>0 # if no sets, but there's wild cards, then you have a set with wilds        
        if regulars.min_by{|card| card.rank}.rank == 1
          sets[0] = [1,1]
        else
          sets[0] = [1,regulars.max_by{|card| card.rank}.rank]
        end
        sets[0][0] += wilds.length        
      elsif wilds.length > 0 # add wilds to highest ranking set
        s = sets.sort{|a,b| b[1]<=>a[1] }.first
        s[0] += wilds.length
      end     
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
        puts "royal flush"
      elsif four_deuces? cards
        result = :four_deuces
        puts "four deuces"
      elsif wild_royal_flush? cards
        result = :wild_royal_flush
        puts "wild royal flush"
      elsif five_of_kind? cards
        result = :five_of_kind
        puts "five of a kind"
      elsif straight_flush? cards
        result = :straight_flush
        puts "straight flush"       
      elsif four_of_kind? cards
        result = :four_of_kind
        puts "four of a kind"
      elsif full_house? cards
        result = :full_house
        puts "full house"
      elsif flush? cards
        result = :flush
        puts "flush"
      elsif straight? cards
        result = :straight
        puts "straight"
      elsif three_of_kind? cards
        result = :three_of_kind
        puts "three of a kind"
      # elsif two_pair? cards
         # result = :two_pair
         # puts "two pair"
      # elsif pair? cards
        # result = :pair
        # puts "pair"
      else
        results = :nothing # add to above?
        puts "nothing"             
      end
      return result
    end
  end
end