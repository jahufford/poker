require 'Qt.rb'

class Card < Qt::GraphicsItem
  attr_reader :width, :height
  attr_accessor :suit, :rank, :front_pixmap, :back_pixmap
  def initialize rank, suit, front_pixmap, back_pixmap
    super nil   
    @rank = rank
    @suit = suit
    @front_pixmap = front_pixmap
    @back_pixmap = back_pixmap
    @width = @front_pixmap.width
    @height = @front_pixmap.height
    @boundingRect = Qt::RectF.new(0, 0, @width, @height)
    @state = :up
  end
  def setMovable move
    setFlag Qt::GraphicsItem::ItemIsMovable, move
  end
  def boundingRect
    return @boundingRect
  end
  def paint painter, options, widget
    if @state == :up
      painter.drawPixmap 0,0,@front_pixmap
      path = Qt::PainterPath.new
      path.addRoundedRect 0,0,@width,@height, 12, 12
      painter.setPen Qt::SolidLine    
   #   painter.setBrush Qt::Brush.new(Qt::black,Qt::SolidPattern)
      #painter.fillRect 0,0,@width,@height,Qt::yellow
      painter.drawPath path
     # painter.drawText 5,20, "#{@rank.to_s} #{@suit.to_s[0].upcase}"
    else
      painter.drawPixmap 0,0, @back_pixmap
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
    update
  end
  def face_down!
    @state = :down
    update
  end
  def mousePressEvent event
    # puts "#{@rank.to_s} #{@suit.to_s}"
    # puts "#{pos().x } #{pos().y} "
    # puts "#{scenePos().x} #{scenePos().y}"
    # puts "----"
    event.ignore # pass to parent
  end
end
