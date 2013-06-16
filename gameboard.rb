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

def pc cards #print cards
  str = ""
  cards.each do |card|
    str += "["+card.rank.to_s+","+card.suit.to_s+"]"
  end    
  puts str
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
    #@view.setWindowTitle "PokerGEMZ"
  
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
    
    grid_layout.addItem @creditsLGW, 0, 0
    grid_layout.addItem @betLGW, 0, 1    
    grid_layout.addItem @bet_downPBGW, 0, 2
    grid_layout.addItem @bet_upPBGW, 0, 3
    grid_layout.addItem @draw_dealPBGW, 0, 4
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
    #pc cards
  # cards = mocked_hand hand, [8,1,6,1,13],[:clubs,:spades,:hearts,:clubs,:diamonds]
    pc cards
    result = JacksOrBetterScoring.score_hand cards
    multiplier = 0
    case result
    when :royal_flush
      multiplier = 200
    when :straight_flush
      multiplier = 100
    when :four_of_kind
      multiplier = 50
    when :full_house
      multiplier = 5
    when :flush
      multiplier = 4
    when :straight
      multiplier = 3
    when :three_of_kind
      multiplier = 2
    when :two_pair
      multiplier = 2
    when :pair
      multiplier = 1
    end
    @credits += @bet*multiplier
    @creditsL.setText("Credits: " + @credits.to_s)
  end
end