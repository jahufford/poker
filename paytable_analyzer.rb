class PaytableAnalyzer < Qt::Dialog
  def initialize rules, paytable
    super nil 
    @rules = rules
    @paytable = paytable
    multipliers = @paytable.multipliers.to_a
    multipliers.sort! {|a,b| b[1]<=>a[1] }    
    paytable_grid = Qt::GridLayout.new
    multipliers.each_with_index do |elem,ind|
      label = Qt::Label.new elem[0].to_s
      label.setFixedWidth 100
      #label.setMinimumWidth 50
      #label.setMaximumWidth 100
      edit = Qt::LineEdit.new elem[1].to_s
      #edit.setMinimumWidth 50
      edit.setFixedWidth 50
      #edit.setMaximumWidth 100
      paytable_grid.addWidget label, ind, 0
      paytable_grid.addWidget edit, ind, 1
    end
    paytable_grid.setSizeConstraint Qt::Layout::SetMaximumSize
    odds_table = Qt::TableWidget.new 32, multipliers.length+4, self
    headers = ["Return","Hold","Total","Nothing"]
    multipliers.each do |item|
      headers << item[0].to_s
    end
    odds_table.setHorizontalHeaderLabels(headers)
    # odds_grid = Qt::GridLayout.new do
      # headers = ["Return","Hold","Total","Nothing"]
      # multipliers.each do |key|
        # headers << key.to_s
      # end
      # headers.each_with_index do |header,ind|
        # label = Qt::Label.new header
        # addWidget label,0,ind
      # end      
    # end
    
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
    @cards = []
    [:heart,:spade,:diamond,:club].each_with_index do |suit,row| # hearts,spades,diamonds,clubs
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
    # top_horiz = Qt::HBoxLayout.new
    # top_horiz.addLayout paytable_grid
    # top_horiz.addWidget odds_table
    top_grid = Qt::GridLayout.new do
      addLayout paytable_grid,0,0
      addWidget odds_table,0,1
    end    
    vert_layout = Qt::VBoxLayout.new do
      addLayout top_grid
      addLayout proposed_hand_layout
      addLayout card_horiz
    end
    setLayout vert_layout
  end
  def deck_card_clicked? pos
    @cards.each_with_index do |card,index|
      if (pos.x>card.pos.x) and (pos.x < (card.pos.x+card.width)) and (pos.y>card.pos.y) and (pos.y<(card.pos.y + card.height))
        if card.up?          
          return index
        end
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
      if @cards[card_ind].up? 
        index = @proposed_hand.find_index{|item| item.rank.nil?}      
        @proposed_hand[index].set(@cards[card_ind])
        @cards[card_ind].down!
      end
    else
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