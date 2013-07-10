#FIX guarantee order of table
class HandAnalyzer < Qt::MainWindow
  slots 'calculate_odds()'
  def initialize rules, paytable, hand=nil
    super nil 
    setWindowTitle "Hand Analyzer"
    @rules = rules
    @paytable = paytable
    multipliers = @paytable.multipliers.to_a
    multipliers.sort! {|a,b| b[1]<=>a[1] }    
    paytable_grid = Qt::GridLayout.new
    multipliers.each_with_index do |elem,ind|
      label = Qt::Label.new elem[0].to_s
      label.setFixedWidth 100
      edit = Qt::LineEdit.new elem[1].to_s
      edit.setFixedWidth 50
      #connect(edit, SIGNAL('editingFinished()'),self,SLOT('calculate_odds()'))
      edit.connect(SIGNAL :editingFinished) do 
        puts "why"
        #calculate_odds()
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
    puts @results.to_s
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
      row[1].each_pair do |key, value|
        @odds_table_array[r][key].setText(value.to_s) 
      end      
    end
  end
  def calculate_odds
    puts "HIHI"
    return unless @proposed_hand.find_index{|card|card.nil_card?}.nil?
    init_odds_table
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
    @results.each_key do |key|
      count_hands key
    end  
    update_odds_table
  end
  def count_hands held    
    held_cards = []
    held.each do |ind|
      held_cards << @proposed_hand[ind]
    end
    case held
      when []
      when [0]
      when [1]
      when [2]
      when [3]
      when [4]
      when [0, 1]
      when [0, 2]
      when [0, 3]
      when [0, 4]
      when [1, 2]
      when [1, 3]
      when [1, 4]
      when [2, 3]
      when [2, 4]
      when [3, 4]
      when [0, 1, 2]
      when [0, 1, 3]
      when [0, 1, 4]
      when [0, 2, 3]
      when [0, 2, 4]
      when [0, 3, 4]
      when [1, 2, 3]
      when [1, 2, 4]
      when [1, 3, 4]
      when [2, 3, 4]
      when [0, 1, 2, 3]
      when [0, 1, 2, 4]
      when [0, 1, 3, 4]
      when [0, 2, 3, 4]
      when [1, 2, 3, 4]
      when [0, 1, 2, 3, 4]
        puts "yoyo"
        result = @rules.score_hand @proposed_hand
        puts result.to_s
        @results[held][result] += 1
    end    
  end
  def brute_force
      # puts "Starting brute force"
    # @results.each_pair do |hold, cols|
      # cols[:total] = find_total(5-hold.length)
    # end
    # # #puts @cards[0]
    # # #puts @proposed_hand[0]
    # #this loops 32 times, for each of every way to play a hand
    # timer = Qt::Time.new
#     
    # cnt = 0
    # time2 = 0
    # timer2 = Qt::Time.new
    # timer.start
    # @results.each_pair do |held, scored|
      # #held is the indexes of @proposed_hand that are kept
    # #  break if cnt == 10000
     # # cnt += 1      
      # puts held.to_s      
      # remaining_cards = @cards.reject{|card| @proposed_hand.find_index(card)} #cards left in the deck #try to replace with include?
      # #now figure all the ways to draw a hand from the remaining cards
      # hand = []
      # (0...47).to_a.combination(5-held.length).each do |comb|        
        # #hand = [] # this will be the hand to score
      # #  break if cnt == 10000
      # #  cnt += 1
        # hand.clear
        # held.each do |i| # add cards from @propsed_hand that were kept
          # hand << @proposed_hand[i]        
        # end
        # comb.each{|i| hand << remaining_cards[i]}
        # timer2.start
        # result = @rules.score_hand(hand)
        # time2 += timer2.elapsed
        # timer2.restart        
        # scored[result] += 1
      # end
    # end    
    # puts @results.to_s
    # puts timer.elapsed
    # puts time2    
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