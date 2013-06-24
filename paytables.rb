# class JacksOrBetterPayTable
  # class << self
    # def return_multiplier hand_result
      # multiplier = 0
      # case hand_result
        # when :royal_flush
          # multiplier = 250
        # when :straight_flush
          # multiplier = 50
        # when :four_of_kind
          # multiplier = 25
        # when :full_house
          # multiplier = 9
        # when :flush
          # multiplier = 6
        # when :straight
          # multiplier = 4
        # when :three_of_kind
          # multiplier = 3
        # when :two_pair
          # multiplier = 2
        # when :pair
          # multiplier = 1
      # end
      # multiplier
    # end
  # end
# end

# class DeucesWildPayTable
  # class << self
    # def return_multiplier hand_result
      # multiplier = 0
      # case hand_result
        # when :royal_flush
          # multiplier = 940        
        # when :four_deuces
          # multiplier = 400
        # when :wild_royal_flush
          # multiplier = 25
        # when :five_of_kind
          # multipler = 16
        # when :straight_flush
          # multiplier = 13
        # when :four_of_kind
          # multiplier = 4
        # when :full_house
          # multiplier = 3
        # when :flush
          # multiplier = 2
        # when :straight
          # multiplier = 2
        # when :three_of_kind
          # multiplier = 1
        # #when :two_pair
        # #  multiplier = 2
        # #when :pair
        # # multiplier = 1
      # end
      # multiplier
    # end
  # end
# end

class BasePaytable < Qt::Object
  slots 'adjust()'
  attr_accessor :multipliers
  def initialize
    super
    @multipliers = Hash.new
  end
  def adjust()
    dialog = PaytableDialog.new nil, @multipliers
    ret = dialog.exec
    if ret == 1
      @multipliers = dialog.new_multipliers      
    end
  end
end

class PaytableDialog < Qt::Dialog
  signals 'paytable_changed(QVariant)'
  attr_reader :new_multipliers
  def initialize parent, multipliers
    super parent
    @new_multipliers = Hash.new
    new_multipliers = @new_multipliers # to keep it accessible down below, the @ screws up the recevier
    setWindowTitle "Adjust Paytable"
    mults = multipliers.to_a.sort{|a,b| b[1] <=> a[1]}  
    dialog = self
    line_edits = Array.new  
    layout = Qt::GridLayout.new do
      mults.each_with_index do |item,index|
        label = Qt::Label.new item[0].to_s
        mult_edit = Qt::LineEdit.new item[1].to_s
        addWidget label, index, 0
        addWidget mult_edit, index, 1
        line_edits << mult_edit
      end
      ok_button = Qt::PushButton.new "Ok"
      ok_button.setDefault true
      ok_button.connect(SIGNAL :clicked) do
      #  new_mult = RubyVariant.new        
        mults.each_with_index do |item, index|
          new_multipliers[item[0]] = line_edits[index].text.to_i
        end        
        #dialog.emit dialog.paytable_changed(new_multipliers.to_variant)
        dialog.accept
      end
      cancel_button = Qt::PushButton.new "Cancel"
      cancel_button.connect(SIGNAL :clicked) do 
        dialog.reject
      end
      
      addWidget cancel_button, mults.length, 0
      addWidget ok_button, mults.length, 1
      
      
    end
    setLayout layout
  end
end

class JacksOrBetterPayTable < BasePaytable
  def initialize
    super
    @multipliers = { royal_flush:250,
                     straight_flush:50,
                     four_of_kind:25,
                     full_house:9,
                     flush:6,
                     straight:4,
                     three_of_kind:3,
                     two_pair:2,
                     pair:1
                   }
  end
  def return_multiplier hand_result    
    return @multipliers[hand_result] if @multipliers.key? hand_result
    return 0
  end
end

class DeucesWildPayTable < BasePaytable
  def initialize
    super
    @multipliers = { royal_flush:940,        
                     four_deuces:400,
                     wild_royal_flush:25,
                     five_of_kind:16,
                     straight_flush:13,
                     four_of_kind:4,
                     full_house:3,
                     flush:2,
                     straight:2,
                     three_of_kind:1
                   }
  end  
  def return_multiplier hand_result
    return @multipliers[hand_result] if @multipliers.key? hand_result
    return 0
  end
end