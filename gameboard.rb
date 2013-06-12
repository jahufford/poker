require 'Qt'# @view.show
require './card.rb'

class MyView < Qt::GraphicsView
  def initialize parent
    super
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
    @view.setWindowTitle "Spider Solitaire"
  
    @border = 15
    @top_space = 50
    @card_spacer = 10
    @overlap = 30
    #there's 10 columns
    @card_width = (@view.width()-(2*@border))/10 - @card_spacer
    @deck = Deck.new @card_width,100, self
    @columns = []
    10.times do
      @columns << Column.new
    end
    add_deck_to_scene
    
  end
  def add_deck_to_scene
    col = 0
    for i in 0...54
      card = @deck.deal_card
      @columns[col] << card
      @scene.addItem card
      col += 1
      col %= 10
    end
    for i in 0...10
       y = @top_space
       x = i*(@card_width+@card_spacer)+@border
       y = @top_space
       @columns[i].each do |card|
         card.setPos x,y
         y += @overlap
       end
    end
    @columns.each do |col| 
      col.last.face_up!
      col.last.setMovable true
    end
  end 
end

class Column < Array
  def initialize
    super    
  end
  def movable?
    # find if mixed suit
  end
end

class Deck
  def initialize card_width, card_height, parent
    #card_width, card_height = 150,200
    @cards = []
    #uses two decks
    [:hearts,:spades,:clubs,:diamonds].each do |suit|
      (1..13).to_a.each do |rank|
        @cards << Card.new(rank, suit, card_width, card_height, self) << Card.new(rank, suit, card_width, card_height, self)
      end
    end
    shuffle
    @index = 0
  end
  def shuffle
    @order = (0...104).to_a.shuffle
  end
  def deal_card
    if @index >= 104
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