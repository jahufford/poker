require 'Qt.rb'

class Card < Qt::GraphicsItem
  def initialize rank, suit, width, height, gameboard
    super nil
    @state = :down
    @rank = rank
    @suit = suit
    @width = width
    @height = height
    @gamebaord = gameboard        
    @boundingRect = Qt::RectF.new(0, 0, @width, @height)    
    # @front_pixmap = Qt::Pixmap.new @width, @height
    # painter = Qt::Painter.new @front_pixmap
    # # painter.setPen Qt::SolidLine    
    # # painter.fillRect 1,1,@width-2,@height-2,Qt::white
    # # painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
    # # painter.drawRect 0,0,@width-1,@height-1
    # # painter.end
    # @back_pixmap = Qt::Pixmap.new @width, @height
    # painter = Qt::Painter.new @back_pixmap
    # path = Qt::PainterPath.new
    # path.addRoundedRect 0,0,@width,@height, 10, 10
    # painter.setPen Qt::SolidLine    
    # painter.setBrush Qt::Brush.new(Qt::yellow,Qt::SolidPattern)
    # painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
    # painter.drawPath path
    # #painter.drawRect 0,0,@width-1,@height-1
    # painter.end
  end
  def setMovable move
    setFlag Qt::GraphicsItem::ItemIsMovable, move
  end
  def boundingRect
    return @boundingRect
  end
  def paint painter, options, widget
    if @state == :up
   #   painter.drawPixmap 0,0, @front_pixmap
      path = Qt::PainterPath.new
      path.addRoundedRect 0,0,@width,@height, 3, 3
      painter.setPen Qt::SolidLine    
      painter.setBrush Qt::Brush.new(Qt::white,Qt::SolidPattern)
      #painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
      painter.drawPath path
      painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
    else
    #  painter.drawPixmap 0,0, @back_pixmap
      path = Qt::PainterPath.new
      path.addRoundedRect 0,0,@width,@height, 3, 3
      painter.setPen Qt::SolidLine
      painter.setBrush Qt::Brush.new(Qt::yellow,Qt::SolidPattern)
      painter.fillRect 1,1,@width-2,@height-2,Qt::yellow
      painter.drawPath path
    end    
  end
  def resize width, height
    @width, @height = width, height
  end
  def flip
    @state = (@state==:down) ? :up : :down
    update
  end
  def face_up!
    @state = :up
  end
  def face_down!
    @state = :down
  end
  def mousePressEvent event
   puts "card press"
  end
end
