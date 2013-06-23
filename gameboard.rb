require 'Qt'
require './card.rb'
require './deck.rb'
# class MyView < Qt::GraphicsView
  # def initialize parent
    # super
  # end  
# end



class Hand < Qt::GraphicsItem
  attr_reader :width, :height, :cards
  def initialize number_of_cards, card_width, card_height
    super nil
    @enabled = false
    @cards = Array.new(number_of_cards) # 5 nils
    @discards = Array.new(number_of_cards)
    @boundary = 10
    @top_boundary = 60
    @space_between_cards = 10
    @boundingRect = Qt::RectF.new(0,0,@boundary*2,@boundary+@top_boundary+200)
    @width = @boundary*2 + 4*@space_between_cards + 5*card_width 
    @height = @boundary + @top_boundary + card_height
  end
  def enable
    @enabled = true
  end
  def disable
    @enabled = false
  end
  def discard    
    @cards.each_with_index do |card, ind|
      if not card.held?
        @discards
        @cards.delete card
      end
    end
  end
  def discards
    @discards.compact
  end
  def add card
    #hand_card = CardInHand.new card
    new_ind = @cards.index(nil)            
    card.setParentItem self
    card.setPos(@boundary + new_ind*(card.width+@space_between_cards), @top_boundary)
    card.face_up!    
    @cards[new_ind] = card    
    @boundingRect.setWidth(@width)
  end
  def clear
    @cards = Array.new(5)
    @discards = Array.new(5)
    items = childItems
    items.each do |item|
      scene.removeItem item
    end
  end
  def boundingRect
    return @boundingRect
  end
  def card_clicked? pos
    #cards can be in either row, the held or the discard row
    all_cards = @cards.zip(@discards) # zip them together, each elemetn of this new array will be a 2 element array
                                      # with one element a card from either row, and the other is a nil 
    all_cards.each_with_index do |card,ind|      
      card = (card.compact)[0]
      if pos.x > card.pos.x and pos.x < card.pos.x+card.width and pos.y > card.pos.y and pos.y < card.pos.y+card.height
        return ind
      end
    end
    false
  end
  def mousePressEvent event
    return if not @enabled
    card_index = card_clicked? event.pos #returns index of card, or false otherwise    
    if card_index
      if @cards[card_index] #if clicked card in @cards, put in discard pile and move up        
         @discards[card_index] = @cards[card_index]
         @cards[card_index] = nil
         #@discards[card_index].face_down!
         @discards[card_index].moveBy 3, -50        
      else #if clicked card is in discard pile, put back in hold pile
        @cards[card_index] = @discards[card_index]
        @discards[card_index] = nil
        #@cards[card_index].face_up!
        @cards[card_index].moveBy -3,+50
      end
    end
  end
  def paint painter, options, widget    
    #painter.drawPixmap 0,0, @front_pixmap
    # path = Qt::PainterPath.new
    # path.addRoundedRect 0,0,@width,@height, 3, 3
    # painter.setPen Qt::SolidLine    
    # painter.setBrush Qt::Brush.new(Qt::white,Qt::SolidPattern)
    # #painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
    # painter.drawPath path       
    #painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
    #@cards.each { |card| card.paint painter}    
  end
end

class MyView < Qt::GraphicsView
  def resizeEvent event
    #puts "resize"
  end
end
   



def pc cards #print cards
  str = ""
  cards.each do |card|
    str += "["+card.rank.to_s+","+card.suit.to_s+"]"
  end    
  puts str
end
  
class Gameboard < Qt::Object
  signals 'quit()'
  attr_accessor :view
  def initialize rules, paytable
    super nil
    @rules = rules
    @paytable = paytable
    @background_color = Qt::Color.new 25,150,25
    @scene = Qt::GraphicsScene.new 0,0, 800,600
    @view = MyView.new @scene    
    @view.backgroundBrush = @background_color
    @view.resize 800,600
    @view.setWindowTitle "PokerGEMZsdfsdfg"
  
    @border = 15
    @top_space = 50
    @card_spacer = 10
    @overlap = 30
    
    @deck = Deck.new self
    @scene.addItem @deck
    @card_width = @deck.card_width
    @card_height = @deck.card_height    
    @deck.setPos 100,100
    @deck.set_on_click self, :draw_deal
    # @deck.connect(SIGNAL :clicked) do
      # draw_deal
    # end
    
    @hand = Hand.new 5, @card_width, @card_height 
    @scene.addItem @hand
    
    @state = :game_off    
    @return_menuPB = Qt::PushButton.new "Return to Menu"
    @return_menuPBGW = @scene.addWidget(@return_menuPB)
    @return_menuPB.connect(SIGNAL :clicked) do
      emit quit
    end
    
    @draw_dealPB = Qt::PushButton.new "Deal"
    @draw_dealPBGW = @scene.addWidget(@draw_dealPB)
    #draw_deal
    @hand.setPos (@view.width-@hand.width)/2, @view.height-@hand.height-100    
   # @draw_deal_pb.move @hand.pos.x+@hand.width+20, @hand.pos.y+@hand.height - @draw_deal_pb.height
    @draw_dealPB.connect(SIGNAL :clicked) do
      draw_deal
    end
    @credits = 500
    @creditsL = Qt::Label.new ("Credits: " + @credits.to_s)
    #@creditsL.setAlignment(Qt::AlignRight)
    @creditsLGW = @scene.addWidget(@creditsL)
    
    @bet = 2
    @betL = Qt::Label.new ("Bet: " + @bet.to_s)    
    @betL.setMinimumWidth( 50)
    @betLGW = @scene.addWidget(@betL)
    
    #@credits_label.setLayoutDirection(Qt::RightToLeft)
    @bet_upPB = Qt::PushButton.new "Up"    
    @bet_upPBGW = @scene.addWidget(@bet_upPB)
    @bet_upPB.connect(SIGNAL :clicked) do
      if @state == :game_off
        @bet += 1 unless @bet==10
        @betL.setText("Bet: " + @bet.to_s)
      end
    end
    @bet_downPB = Qt::PushButton.new "Down"
    @bet_downPBGW = @scene.addWidget( @bet_downPB)
    @bet_downPB.connect(SIGNAL :clicked) do
      if @state == :game_off
        @bet -= 1 unless @bet==1
        @betL.setText("Bet: " + @bet.to_s)
      end
    end
    
    grid_layout = Qt::GraphicsGridLayout.new
    
    grid_layout.addItem @return_menuPBGW, 0,0
    grid_layout.addItem @creditsLGW, 0, 1
    grid_layout.addItem @betLGW, 0, 2    
    grid_layout.addItem @bet_downPBGW, 0, 3
    grid_layout.addItem @bet_upPBGW, 0, 4
    grid_layout.addItem @draw_dealPBGW, 0, 5
    form = Qt::GraphicsWidget.new
    form.setLayout grid_layout
    @scene.addItem form
    form.setPos @hand.pos.x, @hand.pos.y+@hand.height
    
    #game = @view.menuBar().addMenu "&Game"
  end
  def draw_deal
    if @state == :game_on
      @draw_dealPB.setText("Deal")
      @hand.disable
      num_of_discards = @hand.discards.length
      num_of_discards.times do
        @hand.add @deck.deal_card
      end
      score_hand @hand
      @return_menuPB.setEnabled true
      @state = :game_off
    else
      @hand.clear
      @hand.enable
      @deck.shuffle
      @draw_dealPB.setText("Draw")
      5.times do 
        @hand.add @deck.deal_card        
      end
      @credits -= @bet
      @creditsL.setText("Credits: " + @credits.to_s)
      @return_menuPB.setEnabled false
      @state = :game_on
    end
  end
  
  def mocked_hand hand, rank,suit
    cards = hand.cards
    cards.each_with_index do |card, ind|
      card.rank = rank[ind] unless rank[ind].nil?
      card.suit = suit[ind] unless suit[ind].nil?
    end
    cards
  end   
  def score_hand hand
    # test hands in order from highest return to lowest
    # because a straight flush is higher than a straight or a flush
    
    cards = hand.cards
    
    # cards = mocked_hand hand, [1,13,12,10,11],[:heart,:heart,:heart,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,13,2,10,11],[:heart,:heart,:heart,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [2,13,12,10,11],[:heart,:heart,:heart,:heart,:heart] #royal flush wrong
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,13,2,2,11],[:heart,:heart,:heart,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,13,2,2,2],[:heart,:heart,:heart,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [9,13,2,10,11],[:heart,:heart,:heart,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [7,3,4,5,6],[:heart,:heart,:heart,:heart,:heart] #straight flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [2,3,4,5,1],[:heart,:heart,:heart,:heart,:heart] #straight flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [2,3,4,5,1],[:heart,:heart,:heart,:heart,:spade] #straight 
    # @rules.score_hand cards
    # cards = mocked_hand hand, [2,3,4,5,1],[:diamonds,:heart,:heart,:heart,:heart] #straight flush
    # @rules.score_hand cards
    
    #pc cards
    #straight test
    # cards = mocked_hand hand, [5,6,7,2,2],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,7,8,2,2],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,7,9,2,2],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,8,9,2,2],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,7,9,2,2],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,10,13],[nil,nil,nil,nil,nil] #straight
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,9,13],[nil,nil,nil,nil,nil] #not
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,4,5],[nil,nil,nil,nil,nil] #straight #broken
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,4,6],[nil,nil,nil,nil,nil] #not
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,4,6],[nil,nil,nil,nil,nil] #not
    # @rules.score_hand cards
    # pc cards
    
    #flush test
    # cards = mocked_hand hand, [5,7,8,4,5],[:hearts,:hearts,:hearts,:hearts,:hearts]
    # @rules.score_hand cards    
    # cards = mocked_hand hand, [1,6,9,10,13],[:hearts,:hearts,:hearts,:spades,:hearts]
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,6,9,2,13],[:hearts,:hearts,:hearts,:spades,:hearts]
    # @rules.score_hand cards
    
    #3 of kind
    # cards = mocked_hand hand, [1,1,1,4,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three aces
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,4,5],[:hearts,:hearts,:hearts,:spades,:hearts] #three aces
    # @rules.score_hand cards
    # cards = mocked_hand hand, [2,9,3,9,3],[:hearts,:hearts,:hearts,:spades,:hearts] #full house
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,1,2,9,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three aces
    # @rules.score_hand cards
    # cards = mocked_hand hand, [1,2,2,9,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three aces
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,2,2,9,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three 13's
    # @rules.score_hand cards
    # cards = mocked_hand hand, [12,2,10,9,13],[:hearts,:hearts,:hearts,:spades,:hearts] #straight    
    # @rules.score_hand cards
    # cards = mocked_hand hand, [5,2,2,1,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three 1's    
    # @rules.score_hand cards
   # cards = mocked_hand hand, [5,2,2,1,13],[:hearts,:hearts,:hearts,:spades,:hearts] #three 1's    
   # @rules.score_hand cards
    
    # cards = mocked_hand hand, [3,3,3,10,11],[:heart,:spade,:club,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [3,3,2,10,11],[:heart,:spade,:club,:heart,:heart] #royal flush
    # @rules.score_hand cards
    # cards = mocked_hand hand, [3,2,2,10,11],[:heart,:spade,:club,:heart,:spade] #royal flush
    # @rules.score_hand cards
    
    cards = mocked_hand hand, [3,4,5,2,10],[:heart,:spade,:club,:heart,:spade] #royal flush
    @rules.score_hand cards
   # hand conflicts? - order of testing enough?   
   
   # result = @rules.score_hand cards
    # multiplier = @paytable.return_multiplier result
    # @credits += @bet*multiplier
    # @creditsL.setText("Credits: " + @credits.to_s)
  end
end