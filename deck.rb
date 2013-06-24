require './card.rb'

class Deck < Qt::GraphicsItem
  attr_reader :boundingRect, :card_width, :card_height  
  signals 'clicked()'
  def initialize parent
    super nil    
    @cards = []
    #use one deck
    load_card_pix
    i = 0
    [:hearts,:spades,:diamonds,:clubs].each do |suit|
      (1..13).to_a.each do |rank|
        @cards << Card.new(rank, suit, @card_fronts[i], @card_back)
        i += 1
      end
    end
    shuffle    
    @boundary = 10
        
    @boundingRect = Qt::RectF.new(5,0,@card_width,@card_height)
  end
  
  def paint painter, options, widget
    y = 10
    (0..5).each do |x|
      painter.drawPixmap x,y, @card_back
      y -= 2
    end
  end
  def load_card_pix    
    #the image map is 6 row, first row is the row of card of hearts, then spades, diamonds,clubs
    # then 2 jokers
    # and finally 5 card backs
    image_map = Qt::Pixmap.new "card_map1.png"
    @card_width = image_map.width/13
    @card_height = image_map.height/6
    @card_fronts = []
    (0...4).each do |row|
      (0...13).each do |col|
        @card_fronts << image_map.copy(col*@card_width, row*@card_height, @card_width, @card_height)
      end
    end
    card_backs = []
    (0...5).each do |col|
      card_backs << image_map.copy(col*@card_width,5*@card_height,@card_width,@card_height)
    end
    @card_back = card_backs[3]    
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
  def mousePressEvent event
    @on_click_receiver.send(@on_click_func)
  end 
  def set_on_click receiver, func
    @on_click_receiver = receiver
    @on_click_func = func
  end
end