class PaytableAnalyzer < Qt::Widget
  def initialize rules, paytable
    super nil 
    @rules = rules
    @paytable = paytable
    multipliers = @paytable.multipliers.to_a
    multipliers.sort! {|a,b| b[1]<=>a[1] }    
    top_grid = Qt::GridLayout.new
    multipliers.each_with_index do |elem,ind|
      label = Qt::Label.new elem[0].to_s
      edit = Qt::LineEdit.new elem[1].to_s
      top_grid.addWidget label, ind, 0
      top_grid.addWidget edit, ind, 1
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
    
    vert_layout = Qt::VBoxLayout.new do
      addLayout top_grid
      addLayout proposed_hand_layout
      addLayout card_grid
    end
    setLayout vert_layout
  end
  def card_clicked? pos
    @cards.each_with_index do |card,index|
      if (pos.x>card.pos.x) and (pos.x < (card.pos.x+card.width)) and (pos.y>card.pos.y) and (pos.y<(card.pos.y + card.height))
        if card.up?
          card.down!
        end
      end
    end
  end  
  def mousePressEvent pos
    card_clicked? pos
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
  end

end