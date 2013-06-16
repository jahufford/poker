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
  def initialize number_of_cards, card_width
    super nil
    @enabled = false
    @cards = Array.new(number_of_cards) # 5 nils
    @discards = Array.new(number_of_cards)
    @boundary = 10
    @top_boundary = 60
    @space_between_cards = 10
    @boundingRect = Qt::RectF.new(0,0,@boundary*2,@boundary+@top_boundary+200)
    @width = @boundary*2 + 4*@space_between_cards + 5*card_width 
    @height = @boundary + @top_boundary + 100
    #setFlag Qt::GraphicsItem::ItemIsMovable, true
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
    #@width = @boundary*2 + @cards.length*card.width + (@cards.length-1)*@space_between_cards
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
    puts "card index #{card_index}"
    if card_index
      if @cards[card_index] #if clicked card in @cards, put in discard pile and move up
        @discards[card_index] = @cards[card_index]
        @cards[card_index] = nil
        @discards[card_index].moveBy 3, -30
      else #if clicked card is in discard pile, put back in hold pile
        @cards[card_index] = @discards[card_index]
        @discards[card_index] = nil        
        @cards[card_index].moveBy -3,+30
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

class CardInHand
  attr_accessor :card
  def initialize card
    @card = card
    @held = true
  end
  def hold
    @hold = true
  end
  def held?
    @hold
  end
  def paint painter
  end
end

class MyView < Qt::GraphicsView
  def resizeEvent event
    puts "resize"
  end
end
   
  
class Gameboard < Qt::Object
  attr_accessor :view
  def initialize
    super
    @background_color = Qt::Color.new 25,150,25
    @scene = Qt::GraphicsScene.new 0,0, 800,600
    @view = MyView.new @scene    
    @view.backgroundBrush = @background_color
    @view.resize 800,600
    @view.setWindowTitle "PokerGEMZ"
  
    @border = 15
    @top_space = 50
    @card_spacer = 10
    @overlap = 30
    
    @card_width = (@view.width()-(2*@border))/10 - @card_spacer
    @card_height = 100
    @deck = Deck.new @card_width,@card_height, self
    @scene.addItem @deck
    @deck.setPos @view.width-300,100
    
    @hand = Hand.new 5, @card_width 
    @scene.addItem @hand
    
    @state = :game_off
    @draw_dealPB = Qt::PushButton.new "Deal"
    @draw_dealPBGW = @scene.addWidget(@draw_dealPB)
    #draw_deal
    @hand.setPos (@view.width-@hand.width)/2, @view.height-250    
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
    
    grid_layout.addItem @creditsLGW, 0, 0
    grid_layout.addItem @betLGW, 0, 1    
    grid_layout.addItem @bet_downPBGW, 0, 2
    grid_layout.addItem @bet_upPBGW, 0, 3
    grid_layout.addItem @draw_dealPBGW, 0, 4
    form = Qt::GraphicsWidget.new
    form.setLayout grid_layout
    @scene.addItem form
    form.setPos @hand.pos.x, @hand.pos.y+@hand.height    
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
      @state = :game_off    
    else
      @hand.clear
      @hand.enable
      @deck.shuffle
      @draw_dealPB.setText("Draw")
      5.times do 
        @hand.add @deck.deal_card        
      end
      @state = :game_on
    end
  end
  def set_straight hand
    cards = hand.cards
    cards[0].rank = 5
    cards[1].rank = 6
    cards[2].rank = 7
    cards[3].rank = 8
    cards[4].rank = 9
    cards
  end
  def set_3_of_a_kind hand
    cards = hand.cards
    cards[2].rank = 9
    cards[3].rank = 9
    cards[4].rank = 9
  end
  
  def flush? hand
    suit = cards[0].suit
    if cards.select{|card| card.suit == suit}.length == 5
      puts "Flush"
      return true
    end
    false
  end
  def straight? hand
    #still need to handle 10,j,q,k,a the ace fucks it all up
    cards = set_straight hand
    sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
    smallest = sorted[0].rank
    sorted.map!{ |card| card.rank-smallest}
    sum = sorted.reduce{ |sum, elem| sum + elem }    
    
    if sum == 10 # if it's a straight then sorted with be 0,1,2,3,4
      puts "Straight"
      return true
    end
    false
  end
  def straight_flush? hand
    if straight?(hand) and flush?(hand)
      puts "straight flush"
      return true
    end
    false
  end
  def royal_flush? hand
    sorted = cards.sort{ |card1,card2| card1.rank <=> card2.rank}
    #if straight_flush? and sorted.min or max to determine royal flush
  end
  def score_hand hand
    # test hands in order from highest return to lowest
    # because a straight flush is higher than a straight or a flush
    
    #probably should sort first
    
    cards = hand.cards
    #cards.each{ |card| card.suit = :heart}    
        
    
    #3 of a kind
    sorted = cards.sort { |card1,card2| card1.rank<=>card2.rank}
    
    
  end
end