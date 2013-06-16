require 'Qt.rb'

class Card < Qt::GraphicsItem
  attr_reader :width, :height, :suit, :rank
  attr_writer :suit, :rank
  def initialize rank, suit, front_pixmap, gameboard
    super nil   
    @rank = rank
    @suit = suit
    @front_pixmap = front_pixmap
    @width = @front_pixmap.width
    @height = @front_pixmap.height
    #@gameboard = gameboard        
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
      painter.drawPixmap 0,0,@front_pixmap
      path = Qt::PainterPath.new
      path.addRoundedRect 0,0,@width,@height, 12, 12
      painter.setPen Qt::SolidLine    
   #   painter.setBrush Qt::Brush.new(Qt::black,Qt::SolidPattern)
      #painter.fillRect 0,0,@width,@height,Qt::yellow
      painter.drawPath path
     # painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
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
    # puts "#{@rank.to_s} #{@suit.to_s}"
    # puts "#{pos().x } #{pos().y} "
    # puts "#{scenePos().x} #{scenePos().y}"
    # puts "----"
    event.ignore # pass to parent
  end
end
