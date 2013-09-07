#FIX guarantee order of table
class MyLineEdit < Qt::LineEdit
  slots 'edit_func()'
  signals 'multiplier_changed()'
  attr_accessor :hand, :multiplier
  def initialize hand, multiplier
    super multiplier.to_s
    @hand = hand
    @multiplier = multiplier
    connect(self, SIGNAL('editingFinished()'), self, SLOT('edit_func()'))    
  end
  def edit_func    
    if self.text.to_i != @multiplier
      @multiplier = self.text.to_i
      emit multiplier_changed()
    end
  end
end

class HandAnalyzer < Qt::MainWindow
  slots 'calculate_odds()'
  def initialize rules, paytable, hand=nil
    super nil     
    setWindowTitle "Hand Analyzer"
    @rules = rules
    @paytable = paytable
    multipliers = @paytable.multipliers.to_a
    @paytable_multipliers = Hash.new
    multipliers.sort! {|a,b| b[1]<=>a[1] }
    paytable_grid = Qt::GridLayout.new    
    multipliers.each_with_index do |elem,ind|
      label = Qt::Label.new elem[0].to_s
      label.setFixedWidth 100
      #edit = Qt::LineEdit.new elem[1].to_s
      edit = MyLineEdit.new elem[0], elem[1]
      @paytable_multipliers[elem[0]] = edit
      edit.setFixedWidth 50      
      edit.connect(SIGNAL :multiplier_changed) do
        calculate_odds()        
      end
      paytable_grid.addWidget label, ind, 0
      paytable_grid.addWidget edit, ind, 1
    end
    paytable_grid.setSizeConstraint Qt::Layout::SetMaximumSize
    @odds_table = Qt::TableWidget.new 32, multipliers.length+4, self #+4 for return, hold, total, nothing    
    @headers = 
    headers = ["Return","Hold","Total","Nothing"]
    multipliers.each do |item|
      headers << item[0].to_s
    end
    @odds_table.setHorizontalHeaderLabels(headers)
    @odds_table_initialized = false
    nums = [0,1,2,3,4]
    @combinations = [] # all the possible ways to play a hand
    (0..5).each do |num|
      nums.combination(num).to_a.each do |item|
        @combinations << item
      end
    end
    
    load_card_pix
    proposed_hand_layout = Qt::HBoxLayout.new
    proposed_hand_layout.addStretch
    @proposed_hand = []    
    5.times do
      card = Card.new nil,nil,nil,@card_back
      #card.setPixmap @card_back
      @proposed_hand << card
      proposed_hand_layout.addWidget card
    end
    proposed_hand_layout.addStretch
    card_grid = Qt::GridLayout.new
    #load cards
    @cards = []
    [:hearts,:spades,:diamonds,:clubs].each_with_index do |suit,row| # hearts,spades,diamonds,clubs
      (0...13).each do |col|
        card = Card.new col+1,suit, @card_fronts[row*13 + col],@card_back
        @cards << card
        card_grid.addWidget card,row,col  
      end
    end
        
    card_grid.setVerticalSpacing 1
    card_grid.setHorizontalSpacing 1
    card_grid.setSizeConstraint Qt::Layout::SetFixedSize
    card_horiz = Qt::HBoxLayout.new do
      addStretch
      addLayout card_grid
      addStretch
    end    
    top_grid = Qt::GridLayout.new
    top_grid.addLayout paytable_grid,0,0
    top_grid.addWidget @odds_table,0,1
    
    vert_layout = Qt::VBoxLayout.new do
      addLayout top_grid
      addLayout proposed_hand_layout
      addLayout card_horiz
    end
    widget = Qt::Widget.new
    widget.setLayout vert_layout
    setCentralWidget widget
    set_from_passed_in_hand hand
    
    #create a big hash in a hash. The first hash will have all the combination of ways you can hold a hand (30), and 
    # it's value will be another hash that has the hand types (royal flush, pair, etc) as the key with the value being
    # the number of possible hands
    # eg, if you keep the 1st and 3rd card in your hand
    # @results[[1,3]] is a hash with with :royal_flush=>number_of_royal_flushes possible
    #                                     :pair=> number_of_pairs possible and so on
    # @results[[1,3]][:royal_flush] = number of royal flushes possible    
    hand_syms = [:return, :hand, :total, :nothing, :royal_flush, :straight_flush, :four_of_kind,:full_house,:flush,:straight,:three_of_kind,:two_pair,:pair]
    hand_hash = Hash.new
    hand_syms.each do |sym|
      hand_hash[sym] = 0
    end    
    @results = Hash.new
    @combinations.each do |combo|
      @results[combo] = hand_hash.dup
    end
    #puts @results.to_s
   # showMaximized()
    setMinimumWidth(1250)
  end
  def clear_results    
    @results.each_pair do |key, value|
      value.each_pair do |k,v|
        @results[key][k] = 0
      end
    end
  end
  def set_from_passed_in_hand hand
    #set proposed hand to passed in cards
    if not hand.nil?
      card_inds = []
      hand.each do |card|
        card_inds << @cards.find_index{ |c| c.rank==card[0] and c.suit==card[1] }
      end      
      card_inds.each do |i|        
        @cards[i].down!
        index = @proposed_hand.find_index{|item| item.rank.nil?}      
        @proposed_hand[index].set(@cards[i])
      end
    end
    calculate_odds
  end
  def clear_odds_table
    @odds_table.rowCount.each do |row|
      @odds_table.columnCount.each do |column|
        widge = @odds_table.item row, column
        widge.s
      end
    end
  end
  def find_total n
    # n is number of discards
    # (47*..(47-n+1))/(n!)
    return 1 if n==0
    top = 47;
    46.downto(47-n+1) do |i|
      top*=i
    end
    bottom = n
    (n-1).downto(2){|i| bottom *= i}
    top/bottom
  end
  def init_odds_table
    header_syms = [:return, :hand, :total, :nothing, :royal_flush, :straight_flush, :four_of_kind,:full_house,:flush,:straight,:three_of_kind,:two_pair,:pair]
    odds_hash = Hash.new
    header_syms.each do |sym|
      odds_hash[sym] = 0
    end    
    @odds_table_array = Array.new # this gives me an array of hashes that will hold the tableWidgetItems
    for i in 0...32
      @odds_table_array << odds_hash.dup
    end
    if not @odds_table_initialezed
      (0...32).each do |row|      
        (0...(14)).each do |col|          
          widge = Qt::TableWidgetItem.new " #{row} #{col}"
          @odds_table_array[row][header_syms[col]] = widge
          @odds_table.setItem row,col,widge
        end
      end  
    end
    @odds_table_initialized = true
  end
  def update_odds_table    
    results_a = @results.to_a
    results_a.sort!{|a,b| b[1][:total] <=> a[1][:total]}
    results_a.each_with_index do |row, r|
      #puts "#{row.to_s} #{r}"
      row[1].each_pair do |key, value|
        #puts "#{r} #{key.to_s} #{value.to_s}"
        @odds_table_array[r][key].setText(value.to_s)
        #@odds_table_array[r][key].setText("#{r},#{key}, #{row.to_s}") 
      end      
    end
  end
  def calculate_odds
    return unless @proposed_hand.find_index{|card|card.nil_card?}.nil?
    # clear_results
    # brute_force
    # update_odds_table    
    # return
    clear_results
    init_odds_table
    puts "---------------------"
    #show all combinations    
    @combinations.each_with_index do |item,ind|      
      #item is the indexes of cards to hold
      str = ""
      scnt = 0
      item.sort.each do |i| #items are indexes into the hand ie [1,3] means @proposed_hand[1] and @proposed_hand[3] are held, the rest are discard
        (i-scnt).times{str+='_ '}
        scnt = i+1
        str += @proposed_hand[i].rank_s + ' '
      end
      (5-scnt).times{str+='_ '}
      @results[item][:hand] = str
      @results[item][:total] = find_total str.count('_') #total number of possible hands with that hold      
    end
    @results.each_pair do |held, values|
      count_hands held
      sum = 0
      values.each_pair do |hand, count|
        next if [:return,:hand,:total,:nothing].include? hand # skips the non-hands
   #     puts "#{@paytable_multipliers[hand].multiplier} #{count}"
        sum += @paytable_multipliers[hand].multiplier * count
      end
      puts "#{sum} #{values[:total]} #{sum/values[:total]}"
      puts "#{sum.class} #{values[:total].class}"
      values[:return] = sum/values[:total].to_f
    end    
    update_odds_table
  end
  def choose n, r
    if (n<0) or (r<0)
      puts "whoa there, n or r is negative (#{n},#{r})"
      return 0
    end
    numerator = n.downto(n-r+1).reduce(1){|product,value| product*value}
    denominator = r.downto(2).reduce(1){|product,value| product*value}
    numerator/denominator
  end
  def rf_counter discarded_cards
    discard_hash = {:hearts=>[], :diamonds=>[], :spades=>[], :clubs=>[]}
    discarded_cards.each do |card|
     ddiscard_hash[card.suit] << card.rank
    end       
   rf_cnt = 4
    discard_hash.each_pair do |suit, ranks_array|
      cnt = 0
      ranks_array.each{|rank| cnt+=1 if [1,10,11,12,13].include?(rank)}
      rf_cnt -= 1 if cnt>0
    end
   rf_cnt
  end
 
  def count_hands held #held is an array of indices of the held cards in @proposed_hand
    discards = (0..4).to_a.map{|i| i if not held.include?(i)}.compact #indices of discarded cards from @proposed_hand
    discarded_cards = discards.map{|i| @proposed_hand[i] }
    held_cards = held.map{|i| @proposed_hand[i] }    
    sorted_held = held_cards.sort{|a,b,|a.rank <=> b.rank}
    case held
      when []
        sets = @rules.find_sets held_cards
        discard_hash = {:hearts=>[], :diamonds=>[], :spades=>[], :clubs=>[]}
        discarded_cards.each do |card|
          discard_hash[card.suit] << card.rank
        end       
        rf_cnt = 4
        discard_hash.each_pair do |suit, ranks_array|
          cnt = 0
          ranks_array.each{|rank| cnt+=1 if [1,10,11,12,13].include?(rank)}
          rf_cnt -= 1 if cnt>0
        end
        @results[held][:royal_flush] = rf_cnt
        # straight flush test
        @results[held][:straight_flush] = count_straights(held, held_cards, discards, discarded_cards, sets, true) - @results[held][:royal_flush]
        # four of a kind test        
        four_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        # no cards held,  draw the 4 of a kind
        sum = 0
        left_in_deck.each_pair do |rank, num|
          next if num<4
          cards = left_in_deck.dup
          cards.delete(rank)
          sum += choose(num,4)*draw_no_duples(1,cards)
        end
        
        four_k_cnt = sum 
        @results[held][:four_of_kind] = four_k_cnt
        
        # full house test
        fh_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        left_in_deck.each_pair do |rank, num|
          cards = left_in_deck.dup
          cards.delete rank
          three_set_cnt = choose(num, 3);
          sum = 0
          cards.each_pair do |rank,num|
            sum += choose(num,2)
          end
          fh_cnt += three_set_cnt*sum
        end
        # ways to make full house
        # 1. make off of sets held in hand
        # fh_cnt = 0
        # fh_sets = @rules.find_sets(held_cards,true)
        # biggest_set = (fh_sets.max_by{|set| set[0]})[0]
        # if (fh_sets.length <= 2) and (biggest_set<4) # can't have full house if you've held 3 different ranks
                                                     # # and can't have full house if you've have 4 of a kind
          # left_in_deck_minus_hand = left_in_deck.dup
          # h_cnt.each_pair do |rank,num|
            # left_in_deck_minus_hand.delete(rank)
          # end
          # fh_sets.each do |set| # set[0] is number of cards,set[1] is the rank of the card            
            # three_set_cnt = choose(left_in_deck[set[1]], 3-set[0]) # make the 3 of a kind
            # # now make the pair
            # left_in_hand = fh_sets.dup
            # left_in_hand.delete set # if held two different cards, can only make fh with those cards
            # if left_in_hand.length != 0 #draw one or zero more cards
              # two_set_cnt = choose(left_in_deck[left_in_hand[0][1]], 2-left_in_hand[0][0]) #finish the pair
            # else
              # #draw a pair              
              # sum = 0
              # left_in_deck_minus_hand.each_pair do |rank,num|
                # sum += choose(num,2)
              # end
              # two_set_cnt = sum
            # end
            # fh_cnt += three_set_cnt*two_set_cnt
          # end
          # if (fh_sets.length == 1) and (fh_sets[0][0] == 2)
            # # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # # by making the three set with the queen's or sixes, now need to find full house
            # # with a two set of the queens or sixes            
            # sum = 0
            # left_in_deck_minus_hand.each_pair do |rank, num|
              # sum += choose(num,5-fh_sets[0][0])
            # end
            # fh_cnt += sum            
          # end
          # if (fh_sets.length == 1) and (fh_sets[0][0] == 1)
            # # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # # by making the three set with the queen's or sixes, now need to find full house
            # # with a two set of the queens or sixes
            # two_set_cnt = left_in_deck[fh_sets[0][1]] # actually choose(left_in_deck[fh_sets[0][1]],1)
            # sum = 0            
            # left_in_deck_minus_hand.each_pair do |rank, num|
              # sum += choose(num,3)
            # end
            # x = sum*two_set_cnt
            # fh_cnt += x            
          # end
        # end                

        @results[held][:full_house] = fh_cnt
        
        #flush test        
        flush_cnt = 0
        [:hearts,:diamonds,:clubs,:spades].each do |suit|
          suit_cnt = discarded_cards.count{|card|card.suit==suit}
          flush_cnt += choose(13-suit_cnt, 5)
        end
        @results[held][:flush] = flush_cnt - @results[held][:straight_flush] - @results[held][:royal_flush]
        straight_cnt = count_straights held, held_cards, discards, discarded_cards, sets, false        
        @results[held][:straight] = straight_cnt - @results[held][:royal_flush] - @results[held][:straight_flush]
        # three of a kind 
        three_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        
        sum = 0
        left_in_deck.each_pair do |rank, num|
          next if num<3
          cards = left_in_deck.dup
          cards.delete(rank)
          sum += choose(num,3)*draw_no_duples(2,cards)
        end        
        three_k_cnt += sum
           
        @results[held][:three_of_kind] = three_k_cnt
        
        # pair test        
        pair_cnt = 0
        sum = 0 
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        
        # draw the pair
        left_in_deck.each_pair do |rank, num|
          next if num < 2
          next if (rank>1 and rank <= 10)
          cards = left_in_deck.dup
          cards.delete(rank)
          a = choose(num,2)
          b = draw_no_duples(3,cards)
          sum += choose(num,2)*draw_no_duples(3,cards)
        end
        
        pair_cnt = sum
        @results[held][:pair] = pair_cnt
        @results[held][:nothing] = find_nothing held
      when [0],[1],[2],[3],[4]
        sets = @rules.find_sets held_cards
        suit = held_cards[0].suit
        suit_len = held_cards.count{|card| card.suit == suit}
        # royal flush test
        if suit_len != 2
          @results[held][:royal_flush] = 0
        else
          needed = [1,10,11,12,13]
          held_count = held_cards.count{|card| needed.include? card.rank}
          discard_count = discarded_cards.count{|card| (needed.include? card.rank) && (card.suit == suit)}
          if held_count == held.length and discard_count == 0
            @results[held][:royal_flush] = 1
          end
        end
        # straight flush test
        @results[held][:straight_flush] = count_straights held, held_cards, discards, discarded_cards, sets, true
        # four of a kind test
        four_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        # 1 card held,  to draw, make four of a kind from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 4
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 4-num
          to_draw -= r
         # if r <= to_draw
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
         # end              
        end
        
        # draw the 4 of a kind
        if max_hand_set[1] == 1 # can't draw three of kind if you already have a pair, b/c it'd be a FH
         left_in_deck_minus_hand.each_pair do |rank, num|
           sum += choose(num,4)
          end
        end
        
        four_k_cnt = sum 
        @results[held][:four_of_kind] = four_k_cnt
        
        # full house test

        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        # ways to make full house
        # 1. make off of sets held in hand
        fh_cnt = 0
        fh_sets = @rules.find_sets(held_cards,true)
        biggest_set = (fh_sets.max_by{|set| set[0]})[0]
        if (fh_sets.length <= 2) and (biggest_set<4) # can't have full house if you've held 3 different ranks
                                                     # and can't have full house if you've have 4 of a kind
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end
          fh_sets.each do |set| # set[0] is number of cards,set[1] is the rank of the card            
            three_set_cnt = choose(left_in_deck[set[1]], 3-set[0]) # make the 3 of a kind
            # now make the pair
            left_in_hand = fh_sets.dup
            left_in_hand.delete set # if held two different cards, can only make fh with those cards
            if left_in_hand.length != 0 #draw one or zero more cards
              two_set_cnt = choose(left_in_deck[left_in_hand[0][1]], 2-left_in_hand[0][0]) #finish the pair
            else
              #draw a pair              
              sum = 0
              left_in_deck_minus_hand.each_pair do |rank,num|
                sum += choose(num,2)
              end
              two_set_cnt = sum
            end
            fh_cnt += three_set_cnt*two_set_cnt
          end
          if (fh_sets.length == 1) and (fh_sets[0][0] == 2)
            # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # by making the three set with the queen's or sixes, now need to find full house
            # with a two set of the queens or sixes            
            sum = 0
            left_in_deck_minus_hand.each_pair do |rank, num|
              sum += choose(num,5-fh_sets[0][0])
            end
            fh_cnt += sum            
          end
          if (fh_sets.length == 1) and (fh_sets[0][0] == 1)
            # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # by making the three set with the queen's or sixes, now need to find full house
            # with a two set of the queens or sixes
            two_set_cnt = left_in_deck[fh_sets[0][1]] # actually choose(left_in_deck[fh_sets[0][1]],1)
            sum = 0            
            left_in_deck_minus_hand.each_pair do |rank, num|
              sum += choose(num,3)
            end
            x = sum*two_set_cnt
            fh_cnt += x            
          end
        end                

        @results[held][:full_house] = fh_cnt

        # flush test
        if suit_len != 1 # doesn't do anything here, just follows pattern for other holds
          @results[held][:flush]=0
        else          
          discard_suit_cnt = discarded_cards.count{|card| card.suit == suit}
          n = 13 - held.length-discard_suit_cnt
          flush_cnt = choose(n,5-held.length)
          @results[held][:flush] = flush_cnt - @results[held][:royal_flush] - @results[held][:straight_flush] 
        end
        
        straight_cnt = count_straights held, held_cards, discards, discarded_cards, sets, false        
        @results[held][:straight] = straight_cnt - @results[held][:royal_flush] - @results[held][:straight_flush]
        
        # three of a kind test
        three_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #1 card held, 4 to draw, make three of a kind from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 4
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 3-num
          to_draw -= r
         # if r <= to_draw
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
         # end
        end        
        # draw the 3 of a kind
        if max_hand_set[1] == 1 # can't draw three of kind if you already have a pair, b/c it'd be a FH
          left_in_deck_minus_hand.each_pair do |rank, num|
            cards = left_in_deck_minus_hand.dup
            cards.delete(rank)
            sum += choose(num,3)*draw_no_duples(1, cards)            
          end
        end       
         
        three_k_cnt = sum
        @results[held][:three_of_kind] = three_k_cnt
        
        # pair test                
        pair_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #1 cards held, 4 to draw, make pair from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 4
          next if (num != max_hand_set[1]) or (rank <= 10 and rank >1) # need to handle aces
          n = left_in_deck[rank]
          r = 2-num
          to_draw -= r
         # if r <= to_draw
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
         # end              
        end
        
        # draw the pair
        #if max_hand_set[1] == 1
          left_in_deck_minus_hand.each_pair do |rank, num|
            next if ((rank <= 10) and (rank>1))
            cards = left_in_deck_minus_hand.dup
            cards.delete(rank)
            sum += choose(num,2)*draw_no_duples(2,cards)
          end
        #end
        
        pair_cnt = sum
        @results[held][:pair] = pair_cnt
        @results[held][:nothing] = find_nothing held
      when [0, 1],[0,2],[0,3],[0,4],[1,2],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]
        sets = @rules.find_sets held_cards
        suit = held_cards[0].suit
        suit_len = held_cards.count{|card| card.suit == suit}
        #testing for royal flushes
        if suit_len != 2
          @results[held][:royal_flush] = 0
        else
          needed = [1,10,11,12,13]
          held_count = held_cards.count{|card| needed.include? card.rank}
          discard_count = discarded_cards.count{|card| (needed.include? card.rank) && (card.suit == suit)}
          if held_count == held.length and discard_count == 0
            @results[held][:royal_flush] = 1
          end
        end        
        @results[held][:straight_flush] = (count_straights held, held_cards, discards, discarded_cards, sets, true) - @results[held][:royal_flush]
        
        # four of a kind test
        four_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #2 cards held,  to draw, make four of a kind from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 3
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 4-num
          to_draw -= r
          #if r <= to_draw
            #b = choose(n,r)
            #c = draw_no_duples(to_draw, left_in_deck_minus_hand)
            #sum += b*c
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
          #end              
        end
        
        # # draw the 3 of a kind
        # if max_hand_set[1] == 1 # can't draw three of kind if you already have a pair, b/c it'd be a FH
          # left_in_deck_minus_hand.each_pair do |rank, num|
            # sum += choose(num,3)
          # end
        # end
                
        four_k_cnt = sum 
        @results[held][:four_of_kind] = four_k_cnt
        
        # full house test

        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        # ways to make full house
        # 1. make off of sets held in hand
        fh_cnt = 0
        fh_sets = @rules.find_sets(held_cards,true)
        biggest_set = (fh_sets.max_by{|set| set[0]})[0]
        if (fh_sets.length <= 2) and (biggest_set<4) # can't have full house if you've held 3 different ranks
                                                     # and can't have full house if you've have 4 of a kind
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end
          fh_sets.each do |set| # set[0] is number of cards,set[1] is the rank of the card            
            three_set_cnt = choose(left_in_deck[set[1]], 3-set[0]) # make the 3 of a kind
            # now make the pair
            left_in_hand = fh_sets.dup
            left_in_hand.delete set # if held two different cards, can only make fh with those cards
            if left_in_hand.length != 0 #draw one or zero more cards
              two_set_cnt = choose(left_in_deck[left_in_hand[0][1]], 2-left_in_hand[0][0]) #finish the pair
            else
              #draw a pair              
              sum = 0
              left_in_deck_minus_hand.each_pair do |rank,num|
                sum += choose(num,2)
              end
              two_set_cnt = sum
            end
            fh_cnt += three_set_cnt*two_set_cnt
          end
          if (fh_sets.length == 1) and (fh_sets[0][0] == 2)
            # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # by making the three set with the queen's or sixes, now need to find full house
            # with a two set of the queens or sixes            
            sum = 0
            left_in_deck_minus_hand.each_pair do |rank, num|
              sum += choose(num,5-fh_sets[0][0])
            end
            fh_cnt += sum            
          end
        end                

        @results[held][:full_house] = fh_cnt

        # flush test       
        if suit_len != 2
          @results[held][:flush]=0
        else          
          discard_suit_cnt = discarded_cards.count{|card| card.suit == suit}
          n = 13 - held.length-discard_suit_cnt
          flush_cnt = choose(n,5-held.length)
          @results[held][:flush] = flush_cnt - @results[held][:royal_flush] - @results[held][:straight_flush] 
        end
        
        # straight test
        straight_cnt = count_straights held, held_cards, discards, discarded_cards, sets, false        
        @results[held][:straight] = straight_cnt - @results[held][:royal_flush] - @results[held][:straight_flush]
        
        three_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #2 cards held,  to draw, make three of a kind from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 3
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 3-num
          to_draw -= r
        #  if r <= to_draw
         if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
         end
         # end              
        end
        
        # draw the 3 of a kind
        if max_hand_set[1] == 1 # can't draw three of kind if you already have a pair, b/c it'd be a FH
          left_in_deck_minus_hand.each_pair do |rank, num|
            sum += choose(num,3)
          end
        end
        
        three_k_cnt = sum
        @results[held][:three_of_kind] = three_k_cnt
        
        # pair test                
        pair_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #2 cards held, 3 to draw, make pair from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 3
          next if ((num != max_hand_set[1])) or ((rank <= 10) and (rank > 1)) 
          n = left_in_deck[rank]
          r = 2-num
          to_draw -= r
        #  if r <= to_draw
          b = choose(n,r)
          c = draw_no_duples(to_draw, left_in_deck_minus_hand)
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
         # end              
        end
        
        # draw the pair
        if max_hand_set[1] == 1 # can't draw a pair of kind if you already have a pair, b/c it'd be two pair
          left_in_deck_minus_hand.each_pair do |rank, num|
            next if ((rank <= 10) and (rank>1))
            cards = left_in_deck_minus_hand.dup
            cards.delete(rank)
            sum += choose(num,2)*draw_no_duples(1,cards)
          end
        end
        
        pair_cnt = sum
        @results[held][:pair] = pair_cnt
        @results[held][:nothing] = find_nothing held      
      when [0, 1, 2],[0, 1, 3],[0, 1, 4],[0, 2, 3],[0, 2, 4],
           [0, 3, 4],[1, 2, 3],[1, 2, 4],[1, 3, 4], [2, 3, 4]
        sets = @rules.find_sets held_cards      
        suit = held_cards[0].suit
        #held_cards.each {|card| a << card.suit}        
        suit_len = held_cards.count{|card| card.suit == suit}
        #royal flush test
        if suit_len != 3
          @results[held][:royal_flush] = 0
        else
          needed = [1,10,11,12,13]
          held_count = held_cards.count{|card| needed.include? card.rank}
          discard_count = discarded_cards.count{|card| (needed.include? card.rank) && (card.suit == suit) }
          if held_count == held.length and discard_count == 0
            @results[held][:royal_flush] = 1
          end
        end
        @results[held][:straight_flush] = count_straights held, held_cards, discards, discarded_cards, sets, true
        # four of a kind
        held_sets = @rules.find_sets(held_cards)
        discard_sets = @rules.find_sets(discarded_cards)
        # two ways to make sets
        # 1. make sets of of cards that are held
        # 2. make sets off of drawn cards. - in this case, drawing 2, so can't draw 4 of k's
        four_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
#               
        #3 cards held, 2 to draw, so can only make 4 of kinds from held cards
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 2
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 4-num
          to_draw -= r
         # if r <= to_draw
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
         # end              
        end
        
        four_k_cnt = sum        
        @results[held][:four_of_kind] = four_k_cnt
        # full house test

        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        # ways to make full house
        # 1. make off of sets held in hand
        fh_cnt = 0
        fh_sets = @rules.find_sets(held_cards,true)
        if fh_sets.length <= 2 # can't have full house if you've held 3 different ranks
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end
          fh_sets.each do |set| # set[0] is number of cards,set[1] is the rank of the card            
            three_set_cnt = choose(left_in_deck[set[1]], 3-set[0]) # make the 3 of a kind
            # now make the pair
            left_in_hand = fh_sets.dup
            left_in_hand.delete set # if held two different cards, can only make fh with those cards
            if left_in_hand.length != 0 #draw one or zero more cards
              two_set_cnt = choose(left_in_deck[left_in_hand[0][1]], 2-left_in_hand[0][0]) #finish the pair
            else
              #draw a pair              
              sum = 0
              left_in_deck_minus_hand.each_pair do |rank,num|
                sum += choose(num,2)
              end
              two_set_cnt = sum
            end
            fh_cnt += three_set_cnt*two_set_cnt
          end
          if (fh_sets.length == 1) and (fh_sets[0][0] == 2)
            # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # by making the three set with the queen's or sixes, now need to find full house
            # with a two set of the queens or sixes            
            sum = 0
            left_in_deck_minus_hand.each_pair do |rank, num|
              sum += choose(num,5-fh_sets[0][0])
            end
            fh_cnt += sum            
          end
        end                

        @results[held][:full_house] = fh_cnt
        
        # flush test
        puts "#{held.to_s} suit len #{suit_len}"
        if suit_len != 3
          @results[held][:flush]=0
        else          
          discard_suit_cnt = discarded_cards.count{|card| card.suit == suit}
          n = 13 - held.length-discard_suit_cnt
          flush_cnt = choose(n,5-held.length)
          @results[held][:flush] = flush_cnt - @results[held][:royal_flush] - @results[held][:straight_flush] 
        end
        #straight test
            
        straight_cnt = count_straights held, held_cards, discards, discarded_cards, sets, false 

        @results[held][:straight] = straight_cnt - @results[held][:royal_flush] - @results[held][:straight_flush]

        # three of a kind
        held_sets = @rules.find_sets(held_cards)
        discard_sets = @rules.find_sets(discarded_cards)
        # two ways to make sets
        # 1. make sets of of cards that are held
        # 2. make sets off of drawn cards. - in this case, drawing 2, so can't draw 3 of k's
        three_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #3 cards held, only 2 to draw, so can only make 3 of kinds from held cards
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 2
          next if num != max_hand_set[1]
              n = left_in_deck[rank]
              r = 3-num
              to_draw -= r
             # if r <= to_draw
             if to_draw >= 0
               sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
             end
             # end          
        end
        
        three_k_cnt = sum
        @results[held][:three_of_kind] = three_k_cnt
        @results[held][:two_pair]
        
        # pair test                
        pair_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        #3 cards held, 2 to draw, make pair from held cards 
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 2
          next if ((num != max_hand_set[1])) or ((rank <= 10) and (rank > 1)) 
          n = left_in_deck[rank]
          r = 2-num
          to_draw -= r        
          b = choose(n,r)
          c = draw_no_duples(to_draw, left_in_deck_minus_hand)
          if to_draw >= 0
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
        end
        
        # draw the pair
        if max_hand_set[1] == 1 # can't draw a pair if you already have a pair, b/c it'd be two pair
          left_in_deck_minus_hand.each_pair do |rank, num|
            next if ((rank <= 10) and (rank > 1)) 
            cards = left_in_deck_minus_hand.dup
            cards.delete(rank)
            sum += choose(num,2)#*draw_no_duples(1,cards)
          end
        end
        
        pair_cnt = sum
        @results[held][:pair] = pair_cnt
        @results[held][:nothing]
        @results[held][:nothing] = find_nothing held    
      when [0, 2, 3, 4] , [0, 1, 3, 4] , [0, 1, 2, 4] , [0, 1, 2, 3] , [1, 2, 3, 4]
        sets = @rules.find_sets held_cards
        suit = held_cards[0].suit
        suit_len = held_cards.count{|card| card.suit == suit}
        #testing for royal flushes
        if suit_len != 4
          @results[held][:royal_flush] = 0
        else
          needed = [1,10,11,12,13]
          held_count = held_cards.count{|card| needed.include? card.rank}
          discard_count = discarded_cards.count{|card| (needed.include? card.rank) && (card.suit == suit)}
          if held_count == held.length and discard_count == 0
            @results[held][:royal_flush] = 1
          end
        end        
        @results[held][:straight_flush] = count_straights held, held_cards, discards, discarded_cards, sets, true 
        # four of a kind
        held_sets = @rules.find_sets(held_cards)
        discard_sets = @rules.find_sets(discarded_cards)
        # two ways to make sets
        # 1. make sets of of cards that are held
        # 2. make sets off of drawn cards. - in this case, drawing 2, so can't draw 4 of k's
        four_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
#               
        #4 cards held, only 1 to draw, so can only make 4 of kinds from held cards
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        left_in_deck_minus_hand = left_in_deck.dup
        h_cnt.each_pair do |rank,num|
          left_in_deck_minus_hand.delete(rank)
        end        
        h_cnt.each_pair do |rank,num|
          to_draw = 1
          next if num != max_hand_set[1]
          n = left_in_deck[rank]
          r = 4-num
          to_draw -= r
          #if r <= to_draw
          if to_draw >= 0              
            sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
          end
          #end              
        end
        
        four_k_cnt = sum        
        @results[held][:four_of_kind] = four_k_cnt
        
        # full house test

        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
        # ways to make full house
        # 1. make off of sets held in hand
        fh_cnt = 0
        fh_sets = @rules.find_sets(held_cards,true)
        biggest_set = (fh_sets.max_by{|set| set[0]})[0]
        if (fh_sets.length <= 2) and (biggest_set<4) # can't have full house if you've held 3 different ranks
                                                     # and can't have full house if you've have 4 of a kind
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end
          fh_sets.each do |set| # set[0] is number of cards,set[1] is the rank of the card            
            three_set_cnt = choose(left_in_deck[set[1]], 3-set[0]) # make the 3 of a kind
            # now make the pair
            left_in_hand = fh_sets.dup
            left_in_hand.delete set # if held two different cards, can only make fh with those cards
            if left_in_hand.length != 0 #draw one or zero more cards
              two_set_cnt = choose(left_in_deck[left_in_hand[0][1]], 2-left_in_hand[0][0]) #finish the pair
            else
              #draw a pair              
              sum = 0
              left_in_deck_minus_hand.each_pair do |rank,num|
                sum += choose(num,2)
              end
              two_set_cnt = sum
            end
            fh_cnt += three_set_cnt*two_set_cnt
          end
          if (fh_sets.length == 1) and (fh_sets[0][0] == 2)
            # if only one set is held, eg two queen's or three sixes, the above only found full houses
            # by making the three set with the queen's or sixes, now need to find full house
            # with a two set of the queens or sixes            
            sum = 0
            left_in_deck_minus_hand.each_pair do |rank, num|
              sum += choose(num,5-fh_sets[0][0])
            end
            fh_cnt += sum            
          end
        end                

        @results[held][:full_house] = fh_cnt
        
        # flush test
        if suit_len != 4
          @results[held][:flush]=0
        else
         if @proposed_hand[discards[0]].suit == suit
           flush_cnt = 8
         else
           flush_cnt = 9
         end
         @results[held][:flush] = flush_cnt - @results[held][:royal_flush] - @results[held][:straight_flush] 
        end
        straight_cnt = count_straights held, held_cards, discards, discarded_cards, sets, false        
        @results[held][:straight] = straight_cnt - @results[held][:royal_flush] - @results[held][:straight_flush]
        
        # 3 of kind test
        held_sets = @rules.find_sets(held_cards)
        discard_sets = @rules.find_sets(discarded_cards)
        # two ways to make sets
        # 1. make sets of of cards that are held
        # 2. make sets off of drawn cards. - in this case, drawing 2, so can't draw 3 of k's
        three_k_cnt = 0
        h_cnt = Hash.new
        d_cnt = Hash.new
        left_in_deck = Hash.new
        held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
        discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
        (1..13).each do |rank|
          left_in_deck[rank] = 4;
          unless h_cnt[rank].nil?
            left_in_deck[rank] -= h_cnt[rank]
          end
          unless d_cnt[rank].nil?
            left_in_deck[rank] -= d_cnt[rank]
          end
        end
              
        # 4 cards held, only 1 to draw, so can only make 3 of kinds from held cards
        max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
        sum = 0
        if held_sets.length < 2 # if 2 pair is held, can be no 3 of kinds
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end        
          h_cnt.each_pair do |rank,num|
            to_draw = 1
            next if num != max_hand_set[1]
                n = left_in_deck[rank]
                r = 3-num
                to_draw -= r
              #  if r <= to_draw
                if to_draw >= 0
                  sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand) unless to_draw < 0
                end
              #  end              
          end
        end
        three_k_cnt = sum
        @results[held][:three_of_kind] = three_k_cnt        
        @results[held][:two_pair]
        
        # pair test
        sets = @rules.find_sets held_cards
        unless sets.length == 2
          pair_cnt = 0
          h_cnt = Hash.new
          d_cnt = Hash.new
          left_in_deck = Hash.new
          held_cards.each{|card| h_cnt[card.rank] = h_cnt[card.rank].nil? ? 1 : h_cnt[card.rank]+1 }
          discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
          (1..13).each do |rank|
            left_in_deck[rank] = 4;
            unless h_cnt[rank].nil?
              left_in_deck[rank] -= h_cnt[rank]
            end
            unless d_cnt[rank].nil?
              left_in_deck[rank] -= d_cnt[rank]
            end
          end
                
          #4 cards held, 1 to draw, make pair from held cards 
          max_hand_set = h_cnt.max_by{|item| item[1]} #items are [rank,num_in_hand]
          sum = 0
          left_in_deck_minus_hand = left_in_deck.dup
          h_cnt.each_pair do |rank,num|
            left_in_deck_minus_hand.delete(rank)
          end
          h_cnt.each_pair do |rank,num|
            to_draw = 1
            next if ((num != max_hand_set[1])) or ((rank <= 10) and (rank > 1))
            n = left_in_deck[rank]
            r = 2-num
            to_draw -= r        
            b = choose(n,r)
            c = draw_no_duples(to_draw, left_in_deck_minus_hand)
            if to_draw >= 0
              sum += choose(n,r)*draw_no_duples(to_draw, left_in_deck_minus_hand)
            end
          end
        end
        # draw the pair
        # if max_hand_set[1] == 1 # can't draw a pair if you already have a pair, b/c it'd be two pair
          # left_in_deck_minus_hand.each_pair do |rank, num|
            # next if ((rank <= 10) and (rank > 1)) 
            # cards = left_in_deck_minus_hand.dup
            # cards.delete(rank)
            # sum += choose(num,2)#*draw_no_duples(1,cards)
          # end
        # end
        
        pair_cnt = sum
        @results[held][:pair] = pair_cnt        
        @results[held][:nothing]
        #ra = @results[held].to_a
        # sum all the winning hands        
        #total_valued_hands = ra[4...(ra.length)].reduce(0){ |sum,val| sum+val[1]}
        @results[held][:nothing] = find_nothing held
      when [0, 1, 2, 3, 4]
        # all cards kept, can only be one hand, just need to score it
        result = @rules.score_hand @proposed_hand
        puts result.to_s
        @results[held][result] += 1
        #puts @results
    end    
  end
  # draws cards without drawing pairs or 3k's
  # num - number of cards to draw
  # card - cards to draw from in hash of {rank:number_left_in_deck}
  def draw_no_duples num, cards
    def inside_duple_func num, cards
      sum = 0
      if num <= 0
        return 1
      elsif num == 1
        ss = 0
        cards.each_pair do |rank,n|
          ss += n
        end
        return ss
      else
        cards.each_pair do |rank, n|
          c  = cards.dup
          c.delete(rank)
          sum += inside_duple_func(num-1,c)*n
        end
      end
      sum 
    end
    ans = inside_duple_func(num, cards)
    return ans/(num.downto(2).reduce(1){|product,value| product*value})
  end
  def factorial num
    num.downto(2).reduce(1){|product,value| product*value}
  end
  def count_straights held, held_cards, discards, discarded_cards, sets, test_straight_flush=false
    if held_cards.length == 0 #need a special case if no cards are held in the hand            
      if test_straight_flush
        left_in_deck_suits = Hash.new
        (1..13).to_a.each do |rank|
          left_in_deck_suits[rank] = [:hearts,:diamonds,:clubs,:spades]
        end
        discarded_cards.each do |card|
          left_in_deck_suits[card.rank].delete(card.suit)
        end
        left_in_deck_suits[14] = left_in_deck_suits[1].dup
        straight_flush_cnt = 0
        [:hearts,:diamonds,:clubs,:spades].each do |suit|          
          1.upto(10) do |i|
            tmp = 0
            i.upto(i+4) do |rank|
              tmp = tmp+1 if left_in_deck_suits[rank].include? suit
            end        
            straight_flush_cnt += 1 if tmp == 5
          end
        end
        return straight_flush_cnt
      end
      d_cnt = Hash.new
      left_in_deck = Hash.new
      discarded_cards.each{|card| d_cnt[card.rank] = d_cnt[card.rank].nil? ? 1 : d_cnt[card.rank]+1 }
      (1..13).each do |rank|
        left_in_deck[rank] = 4;
        unless d_cnt[rank].nil?
          left_in_deck[rank] -= d_cnt[rank]
        end
      end      
      left_in_deck[14] = left_in_deck[1]
      straight_cnt = 0
      1.upto(10) do |i|
        tmp = 1;
        i.upto(i+4) do |rank|
          tmp *= left_in_deck[rank]
        end        
        straight_cnt += tmp
      end
      return straight_cnt
    end    
    held_cards = held_cards.map { |card|card.dup } # need to copy held_cards so 1 doesn't change to 14    
    straight_cnt = 0
    if test_straight_flush
      suit = held_cards[0].suit
      if held_cards.count{|card|card.suit == suit} != held_cards.length #if all held cards aren't the same suit
        return 0
      end
    end
    if sets.length == 0
      #could be possible straights    
      max = held_cards.max_by{|card| card.rank}.rank
      min = held_cards.min_by{|card| card.rank}.rank 
      #determine whether to handle an ace as a 1 or a 14
      if max > 6
        i = held_cards.find_index{|card| card.rank == 1}
        if not i.nil?
          held_cards[i].rank = 14
          i = discarded_cards.find_index{|card| card.rank == 1}
          discarded_cards[i].rank = 14 unless i.nil?
        end
      end
      if max-min < 5
        parts = 5 - (max-min)
        #puts "parts #{parts} #{max} #{min}"
        inside = (max-min+1)-held.length # inside draws
        outside = discards.length - inside
        adjusted_parts = parts
        #need to adjust whether or not the run is at the ends of the hand
        if min - outside <1
          adjusted_parts = parts - (1 - (min-outside))
        elsif max + outside > 14
          adjusted_parts = parts - (max+outside - 14)
        end         
        if min - outside > 0            
          window_base_rank = min - outside
        else
          window_base_rank = 1
        end
        #now make a sliding window containing discards.length
        used_parts = 0
        straight_cnt = 0
   #     puts "#{held.to_s} max #{max} | min #{min} | win rank #{window_base_rank} | parts #{parts} | adjusted #{adjusted_parts} | inside #{inside} | outside #{outside}"
        begin
          chosen = 0
          until held_cards.find_index{|card| card.rank==window_base_rank}.nil?
            window_base_rank += 1
          end
          straight_cards = [window_base_rank]
          while straight_cards.length < discards.length
            test = straight_cards.last + 1
            until held_cards.find_index{|card| card.rank==test}.nil?
              test += 1
            end
            straight_cards << test
          end
    #      puts straight_cards.to_s
          straight_cnt_this_window = 1
          straight_cards.each do |straight_card|              
            if held_cards.find_index{|card| card.rank == straight_card}.nil?
              if test_straight_flush
                # see if a card was thrown away
                cnt = 1-discarded_cards.count{|card| card.rank==straight_card and card.suit==suit}
                cnt *= 1-held_cards.count{|card| card.rank==straight_card and card.suit==suit}
                #straight_cnt_this_window *= 1-cnt
                straight_cnt_this_window *= cnt
              else
                 straight_cnt_this_window *= 4-discarded_cards.count{|card| card.rank == straight_card}
              end
              dis_cnt = discarded_cards.count{|card| card.rank==straight_card and card.suit==suit}              
     #         puts "#{dis_cnt} dis " 
              #puts "#{held.to_s} max #{max} | min #{min} | win rank #{window_rank} | parts #{parts} | adjusted #{adjusted_parts} | discnt #{dis_cnt} | inside #{inside} | outside #{outside}"                
            end
          end
          straight_cnt += straight_cnt_this_window
          window_base_rank += 1
          used_parts += 1
        end while used_parts < adjusted_parts
      end          
    else
      # no possible straights
      straight_cnt = 0
    end
    return straight_cnt
  end
  def find_nothing held
    ra = @results[held].to_a
    # sum all the winning hands        
    total_valued_hands = ra[4...(ra.length)].reduce(0){ |sum,val| sum+val[1]}
    @results[held][:total] - total_valued_hands
  end
  # def held_cards indices
    # held = Array.new
    # indices.each do |i|      
      # held << @proposed_hand[i]
    # end
    # held
  # end
  def brute_force
      puts "Starting brute force"
    @results.each_pair do |hold, cols|
      cols[:total] = find_total(5-hold.length)
    end
    # #puts @cards[0]
    # #puts @proposed_hand[0]
    #this loops 32 times, for each of every way to play a hand
    timer = Qt::Time.new
    
    cnt = 0
    time2 = 0
    timer2 = Qt::Time.new
    timer.start
    @results.each_pair do |held, scored|
      #held is the indexes of @proposed_hand that are kept
    #  break if cnt == 10000
     # cnt += 1      
      puts held.to_s      
      remaining_cards = @cards.reject{|card| @proposed_hand.find_index(card)} #cards left in the deck #try to replace with include?
      #now figure all the ways to draw a hand from the remaining cards
      hand = []
      (0...47).to_a.combination(5-held.length).each do |comb|        
        #hand = [] # this will be the hand to score
      #  break if cnt == 10000
      #  cnt += 1
        hand.clear
        held.each do |i| # add cards from @propsed_hand that were kept
          hand << @proposed_hand[i]        
        end
        comb.each{|i| hand << remaining_cards[i]}
        timer2.start
        result = @rules.score_hand(hand)
        time2 += timer2.elapsed
        timer2.restart        
        scored[result] += 1
      end
    end    
    puts @results.to_s
    puts timer.elapsed
    puts time2    
  end
  def deck_card_clicked? pos
    @cards.each_with_index do |card,index|
      if (pos.x>card.pos.x) and (pos.x < (card.pos.x+card.width)) and (pos.y>card.pos.y) and (pos.y<(card.pos.y + card.height))        
        return index
      end
    end    
    false
  end
  def proposed_hand_card_clicked? pos
    @proposed_hand.each_with_index do |card,index|
      if (pos.x>card.pos.x) and (pos.x < (card.pos.x+card.width)) and (pos.y>card.pos.y) and (pos.y<(card.pos.y + card.height))
        if card.up?          
          return index
        end
      end
    end    
    false
  end
  def mousePressEvent pos
    card_ind = deck_card_clicked?(pos)
    if card_ind
      if @cards[card_ind].up? and not @proposed_hand.find_index{|card| card.nil_card?}.nil?
        index = @proposed_hand.find_index{|item| item.rank.nil?}      
        @proposed_hand[index].set(@cards[card_ind])
        if @proposed_hand.find_index{|card| card.nil_card?}.nil?
          calculate_odds
        end
        @cards[card_ind].down!
      elsif @cards[card_ind].down?
        card = @cards[card_ind]
        card.up!
        #remove from proposed hand
        pcard_index = @proposed_hand.find_index{|item| item.rank==card.rank and item.suit==card.suit}
        @proposed_hand[pcard_index].clear        
      end
    end
    card_ind = proposed_hand_card_clicked?(pos)
    if card_ind
      card = @proposed_hand[card_ind]
      if not card.nil_card?
        cards_index = @cards.find_index{|item| item.rank==card.rank and item.suit==card.suit}
        card.clear
        @cards[cards_index].up!
      end
    end
  end
  def load_card_pix    
    #the image map is 6 row, first row is the row of card of hearts, then spades, diamonds,clubs
    # then 2 jokers
    # and finally 5 card backs
    image_width = 50
    image_map = Qt::Pixmap.new "card_map1.png"
    @card_width = image_map.width/13
    @card_height = image_map.height/6
    @card_fronts = []
    (0...4).each do |row|
      (0...13).each do |col|
        @card_fronts << image_map.copy(col*@card_width, row*@card_height, @card_width, @card_height).scaledToWidth(image_width,Qt::SmoothTransformation)
      end
    end
    card_backs = []
    (0...5).each do |col|
      card_backs << image_map.copy(col*@card_width,5*@card_height,@card_width,@card_height).scaledToWidth(image_width,Qt::SmoothTransformation)
    end
    @card_back = card_backs[3]    
  end  
  class Card < Qt::Label
    attr_accessor :rank,:suit,:card_front,:card_back,:state,:width,:height
    def initialize rank,suit,card_front,card_back
      super nil
      @rank = rank
      @suit = suit
      @card_front = card_front
      @card_back = card_back
      @width = card_back.width
      @height = card_back.height
      @state = :up
      if card_front.nil?
        setPixmap @card_back
      else
        setPixmap @card_front
      end
    end
    def rank_s
      return @rank.to_s if @rank>=2 and @rank<=10
      return "A" if @rank==1
      return "J" if @rank==11
      return "Q" if @rank==12
      return "K" if @rank==13
    end
    def up?
      @state == :up
    end
    def up!
      @state = :up
      setPixmap @card_front
    end
    def down?
      @state == :down
    end
    def down!
      @state = :down
      setPixmap @card_back
    end
    def flip
      if @state == :up
        setPixmap @card_back
      else
        setPixmap @card_front
      end
    end
    def set card
      @rank = card.rank
      @suit = card.suit
      @card_front = card.card_front
      setPixmap @card_front      
    end
    def clear
      @rank = nil
      @suit = nil
      setPixmap @card_back      
    end
    def nil_card?
      @rank.nil?
    end
    def ==(obj)
      if obj.class == self.class        
        return (@rank==obj.rank and @suit==obj.suit)
      end
      false
    end
  end
end