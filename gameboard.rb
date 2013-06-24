require 'Qt'
require './card.rb'
require './deck.rb'
# class MyView < Qt::GraphicsView
  # def initialize parent
    # super
  # end  
# end


class PayoutBoard < Qt::GraphicsWidget
  slots 'update_paytable(QVariant)'
  def initialize scene, paytable
    super()
    @scene = scene    
    @paytable = paytable
    mults = @paytable.multipliers.to_a.sort{|a,b| b[1]<=>a[1]}
    layout = Qt::GraphicsGridLayout.new self
    oddsGW = Qt::GraphicsWidget.new self
    oddsGTI = Qt::GraphicsTextItem.new "Odds of Drawing", oddsGW
    layout.setColumnMinimumWidth 0,100
    layout.addItem oddsGW,0,3
    @hand_labels = Hash.new
    @multiplier_labels = Hash.new    
    mults.each_with_index do |item, index|      
      handGW = Qt::GraphicsWidget.new self
      handGTI = Qt::GraphicsTextItem.new item[0].to_s, handGW      
      @hand_labels[item[0]] = handGTI      
      multiplierGW = Qt::GraphicsWidget.new self
      multiplierGTI = Qt::GraphicsTextItem.new item[1].to_s, multiplierGW
      @multiplier_labels[item[0]] = multiplierGTI
      layout.setRowMaximumHeight index, 20      
      #child[0].setDefaultTextColor Qt::Color.new (Qt::red)
      layout.addItem handGW, index+1, 0
      layout.addItem multiplierGW, index+1, 1
    end
    setLayout layout
    resize 300,500
  end
  def update_paytable new_multipliers
    hash = new_multipliers.value.value    
    hash.each_key do |key|
      @multiplier_labels[key].setPlainText hash[key].to_s
    end
  end
  def highlight hand
    if @hand_labels.has_key? hand
      @hand_labels[hand].setDefaultTextColor Qt::Color.new(Qt::red)
      @multiplier_labels[hand].setDefaultTextColor Qt::Color.new(Qt::red)
    end
  end
  def clear_highlights
    @hand_labels.each_key do |key|
      @hand_labels[key].setDefaultTextColor Qt::Color.new(Qt::black)
      @multiplier_labels[key].setDefaultTextColor Qt::Color.new(Qt::black)    
    end
  end  
end

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
    all_cards = @cards.zip(@discards) # zip them together, each element of this new array will be a 2 element array
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
         @discards[card_index].discard
      else #if clicked card is in discard pile, put back in hold pile
        @cards[card_index] = @discards[card_index]
        @discards[card_index] = nil
        #@cards[card_index].face_up!
        @cards[card_index].moveBy -3,+50
        @cards[card_index].hold
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
    @creditsL.setMinimumWidth 130
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
    
    @payout_board = PayoutBoard.new @scene, @paytable
    @scene.addItem @payout_board
    #@payout_board.setPos @view.width-@payout_board.width-50, 50
    @payout_board.setPos 500,0
    connect(@paytable, SIGNAL('adjusted(QVariant)'), @payout_board, SLOT('update_paytable(QVariant)'))
    #game = @view.menuBar().addMenu "&Game"
    @hand_overGTI = @scene.addText "Time to draw a new hand!"
    @hand_overGTI.setPos 200,form.pos.y+50
  end
  def draw_deal
    if @state == :game_on
      @payout_board.clear_highlights
      @draw_dealPB.setText("Deal")
      @hand.disable
      num_of_discards = @hand.discards.length
      num_of_discards.times do
        @hand.add @deck.deal_card
      end
      score_hand @hand
      @return_menuPB.setEnabled true
      @hand_overGTI.setPlainText("Time to draw a new hand!")
      @state = :game_off
    else
      @payout_board.clear_highlights      
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

      result_of_draw = @rules.score_hand @hand.cards
      @payout_board.highlight result_of_draw
      @hand_overGTI.setPlainText("")
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
  
   
    result = @rules.score_hand cards
    $statusBar.showMessage(result.to_s,2000)
    Qt::Application.processEvents   
    multiplier = @paytable.return_multiplier result
    @credits += @bet*multiplier
    @creditsL.setText("Credits: " + @credits.to_s)
    @payout_board.highlight result
  end
end