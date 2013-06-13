require 'Qt'# @view.show
require './card.rb'

# class MyView < Qt::GraphicsView
  # def initialize parent
    # super
  # end  
# end

class Deck < Qt::GraphicsItem
  attr_reader :boundingRect
  def initialize card_width, card_height, parent
    super nil    
    @cards = []
    #use one deck
    [:hearts,:spades,:clubs,:diamonds].each do |suit|
      (1..13).to_a.each do |rank|
        @cards << Card.new(rank, suit, card_width, card_height, self)
      end
    end
    shuffle    
    @boundary = 10
    @boundingRect = Qt::RectF.new(0,0,@boundary*2,@boundary*2)
    @width = 100
    @height = 100
  end
  def discard
    @discards = []
    @cards.each do |card|
      if not card.held?
        @discards << card
        @cards.delete card
      end
    end
  end
  def discarded_cards
    
  end  
  def paint painter, options, widget    
   #   painter.drawPixmap 0,0, @front_pixmap
    path = Qt::PainterPath.new
    path.addRoundedRect 0,0,@width,@height, 3, 3
    painter.setPen Qt::SolidLine    
    painter.setBrush Qt::Brush.new(Qt::white,Qt::SolidPattern)
      # #painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
    painter.drawPath path
#      painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
    
  end
  def shuffle
    @order = (0...52).to_a.shuffle
    @index = 0
  end
  def deal_card
    if @index >= 52
      return nil
    end
    card = @cards[@order[@index]]
    @index += 1    
    card
  end
  def resize width, height
    @cards.each{|card| card.resize width,height}
  end  
end

class Hand < Qt::GraphicsItem
  attr_reader :width, :height
  def initialize number_of_cards, card_width
    super nil
    @enabled = false
    @cards = []
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
  def add card
    hand_card = CardInHand.new card
    card.setParentItem self
    card.setPos(@boundary + @cards.length*(card.width+@space_between_cards), @top_boundary)
    card.face_up!
    @cards << card
    #@width = @boundary*2 + @cards.length*card.width + (@cards.length-1)*@space_between_cards
    @boundingRect.setWidth(@width)
  end
  def clear
    @cards.clear
    items = childItems
    items.each do |item|
      scene.removeItem item
    end
  end
  def boundingRect
    return @boundingRect
  end
  def card_clicked? pos
    @cards.each do |card|
      if pos.x > card.pos.x and pos.x < card.pos.x+card.width and pos.y > card.pos.y and pos.y < card.pos.y+card.height
        return card
      end
    end
    false
  end
  def mousePressEvent event
    return if not @enabled
    card_clicked = card_clicked? event.pos
    if card_clicked
      if card_clicked.held?
        card_clicked.unhold!
        card_clicked.moveBy 0, -10
      else
        card_clicked.hold!
        card_clicked.moveBy 0,+10
      end
    end
    #puts "#{pos().x} #{pos.y()}"
    #puts "#{scenePos().x} #{scenePos.y()}"
  end
  def paint painter, options, widget    
    #painter.drawPixmap 0,0, @front_pixmap
    path = Qt::PainterPath.new
    path.addRoundedRect 0,0,@width,@height, 3, 3
    painter.setPen Qt::SolidLine    
    painter.setBrush Qt::Brush.new(Qt::white,Qt::SolidPattern)
    #painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
    painter.drawPath path       
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

class Gameboard < Qt::Object
  attr_accessor :view
  def initialize
    super
    @background_color = Qt::Color.new 25,150,25
    @scene = Qt::GraphicsScene.new 0,0, 800,600
    @view =Qt::GraphicsView.new @scene    
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
    puts "#{form.height}"
  end
  def draw_deal
    if @state == :game_on
      @draw_dealPB.setText("Deal")
      @hand.disable
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
      
  
  
  def add_deck_to_scene
    # col = 0
    # for i in 0...54
      # card = @deck.deal_card
      # @columns[col] << card
      # @scene.addItem card
      # col += 1
      # col %= 10
    # end
    # for i in 0...10
       # y = @top_space
       # x = i*(@card_width+@card_spacer)+@border
       # y = @top_space
       # @columns[i].each do |card|
         # card.setPos x,y
         # y += @overlap
       # end
    # end
    # @columns.each do |col| 
      # col.last.face_up!
      # col.last.setMovable true
    # end
  end 
end