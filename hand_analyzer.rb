class HandAnalyzer < Qt::Dialog
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
      connect(edit, SIGNAL('editingFinished()'),self,SLOT('calculate_odds()'))
      paytable_grid.addWidget label, ind, 0
      paytable_grid.addWidget edit, ind, 1
    end
    paytable_grid.setSizeConstraint Qt::Layout::SetMaximumSize
    @odds_table = Qt::TableWidget.new 32, multipliers.length+4, self
    headers = ["Return","Hold","Total","Nothing"]
    multipliers.each do |item|
      headers << item[0].to_s
    end
    @odds_table.setHorizontalHeaderLabels(headers)
    nums = [0,1,2,3,4]
    @combinations = []
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
    setLayout vert_layout
    set_from_passed_in_hand hand
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
  def calculate_odds
    return unless @proposed_hand.find_index{|card|card.nil_card?}.nil?
    #show all combinations
    @combinations.each_with_index do |item,ind|
      # item is the indexes of cards to hold
      str = ""
      scnt = 0
      item.sort.each do |i| #items are indexes into the hand ie [1,3] means @proposed_hand[1] and @proposed_hand[3] are held, the rest are discard
        (i-scnt).times{str+='_'}
        scnt = i+1
        str += @proposed_hand[i].rank_s
      end
      (5-scnt).times{str+='_'}
      widge = Qt::TableWidgetItem.new str
      @odds_table.setItem ind, 1, widge
    end
    #fill out total number of possible hands
    (0...32).each do |i|
      total = find_total @odds_table.item(i,1).text.count('_')
      widge = Qt::TableWidgetItem.new total.to_s
      @odds_table.setItem i,2, widge
    end    
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
    attr_reader :rank,:suit,:card_front,:card_back,:state,:width,:height
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
  end
end