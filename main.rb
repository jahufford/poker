# def combo array, n
  # combs = []
  # (0...(array.length-n+1)
# end
# 
# nums = [1,2,3,4,5]
# combinations = [[],nums]
# nums.each {|num| combinations << [num]}
# nums[0...(nums.length-1)].each_with_index do |num,ind|
  # nums[(ind+1)...(nums.length)].each do |inside|
    # combinations << [num,inside]
  # end  
# end

require 'Qt'
require './gameboard.rb'
require './rules.rb'
require './paytables.rb'
require './hand_analyzer.rb'
require 'net/http'
require 'uri'

$VERSION = 1
$START_CREDITS = 100
class RubyVariant < Qt::Variant
  # all these shenanigans is necessary to be able to emit
  # ruby objects from a signal. You can emit a ruby class by wrapping it in
  # a QVariant, but the built in ruby hash won't work with this, it needs
  # to be wrapped inside another class  
  def initialize value
    super()    
    @value = value
  end
  def value
    @value
  end
  class MyHash
    attr_accessor :value
    def initialize value
      @value = value
    end
  end
end
class Hash
  def to_variant
    RubyVariant.new RubyVariant::MyHash.new(self)
  end
end

class OptionsDialog < Qt::Dialog
  def initialize
    super
    setWindowTitle "PokerGEMZ Options"
  end
end

class MainMenu < Qt::Widget  
  signals 'selection(QVariant)'
  attr_reader :layout
  def initialize
    super
    buttons = Array.new
    ["Jacks or Better","Deuces Wild", "Joker Poker"].each do |elem|
      gamePB = Qt::PushButton.new elem
      gamePB.connect(SIGNAL :clicked) do
        emit selection(RubyVariant.new(elem))
      end
      analyzePB = Qt::PushButton.new "Analyze Hands"
      analyzePB.connect(SIGNAL :clicked) do
        emit selection(RubyVariant.new("analyze hands "+elem))
      end
      buttons << [gamePB,analyzePB]
    end
    # jacks_or_betterPB = Qt::PushButton.new "Jacks or Better"
    # jacks_or_betterPB.connect(SIGNAL :clicked) do
      # emit selection(RubyVariant.new("jacks_or_better"))
    # end
    # analyze_pt_jacksPB = Qt::PushButton.new "Analyze Paytable"
    # analyze_pt_jacksPB.connect(SIGNAL :clicked) do
      # emit selection(RubyVariant.new("analyze_pt_jacks_or_better"))
    # end
    # deuces_wildPB = Qt::PushButton.new "Deuces Wild"
    # deuces_wildPB.connect(SIGNAL :clicked) do
      # emit selection(RubyVariant.new("deuces_wild"))
    # end
    # analyze_pt_deucesPB = Qt::PushButton.new "Analyze Paytable"
    # analyze_pt_deucesPB.connect(SIGNAL :clicked) do
      # emit selection(RubyVariant.new("analyze_pt_deuces_wild"))
    # end
    @layout = Qt::VBoxLayout.new do
       addStretch
       buttons.each do |elem|
         l = Qt::GridLayout.new do
          addWidget elem[0],0,0
          addWidget elem[1],0,1
         end
         addLayout l
       end
       #addWidget jacks_or_betterPB    
       #addWidget deuces_wildPB
       addStretch
    end
    # layout = Qt::GridLayout.new do
      # addWidget jacks_or_betterPB, 0, 0
      # addWidget analyze_pt_jacksPB, 0, 1
      # addWidget deuces_wildPB, 1,0
    # end
    setLayout layout    
  end
end


class MyButton < Qt::AbstractButton
  def initialize text
   super nil
   setText text
  end
  def paintEvent event    
    painter Qt::Painter.new self
    brush = Qt::Brush.new Qt::Red
    painter.fillRect 0,0,10,10,brush
  end
end
  
class MainWindow < Qt::MainWindow
  slots 'construct_game(QVariant)','show_main_menu()','update_credits(int)'
  def initialize
    super
    setWindowTitle "PokerGEMZ"
    #gameboard = Gameboard.new
    setup_menubar    
    $statusBar = statusBar()
    statusBar.show
    @credits_label = Qt::Label.new "$"
   
    update_credits 100    
    show_main_menu
    # @gameboard = Gameboard.new( DeucesWildScoring,DeucesWildPayTable)
    # setCentralWidget @gameboard.view    
    # resize(@gameboard.view.width+100, @gameboard.view.height+100)
    @options = {:discard_style=>:flip}
    resize 800,600
  end
  def show_main_menu
    @paytable_action.setEnabled false 
    @analyzer_action.setEnabled false
    @discard_style_action.setEnabled true
    @gameboard.view.hide unless @gameboard.nil?
    @main_menu = MainMenu.new 
    @main_menu.connect(SIGNAL('selection(QVariant)')) do |game|
      construct_game game.value
    end
    layout = Qt::VBoxLayout.new
    layout.addWidget @main_menu
    #puts @credits_label.text
    @credits_label = Qt::Label.new "Credits:  $#{@credits.to_s}"    
    layout.addWidget @credits_label
    layout.addStretch    
    widge = Qt::Widget.new
    widge.setLayout layout
    
    setCentralWidget widge
    #update
    #@main_menu.resize(@gameboard.view.width, @gameboard.view.height)
  end
  def update_credits credits
    @credits = credits    
  end
  def construct_game game
    case game.downcase
    when "jacks or better"
      rules = JacksOrBetterScoring
      paytable = JacksOrBetterPayTable.new
      setWindowTitle "PokerGEMZ - Jacks or Better"      
    when "deuces wild"
      rules = DeucesWildScoring
      paytable = DeucesWildPayTable.new
      setWindowTitle "PokerGEMZ - Deuces Wild"
    when "analyze hands jacks or better"
      rules = JacksOrBetterScoring
      paytable = JacksOrBetterPayTable.new
      setWindowTitle "PokerGEMZ - Paytable Analyzer - Jacks or Better"      
    else
      puts game
      Qt::MessageBox.warning self, "Oops", "Not implemented yet"      
      return
    end
    if game.start_with? "analyze"
      HandAnalyzer.new(rules,paytable).show
      #setCentralWidget HandAnalyzer.new rules, paytable
    else
      @gameboard = Gameboard.new(rules,paytable,@credits,@options)
      connect(@gameboard,SIGNAL('updated_credits(int)'),self, SLOT('update_credits(int)'))
      status = statusBar()    
      @paytable_action.setEnabled true
      @discard_style_action.setEnabled false
      connect(@paytable_action,SIGNAL('triggered()'),paytable, SLOT('adjust()'))
      connect(@gameboard,SIGNAL('quit()'),self,SLOT('show_main_menu()'))
      @analyzer_action.setEnabled true
      connect(@analyzer_action, SIGNAL(:triggered), @gameboard, SLOT('run_analyzer()'))      
      resize(@gameboard.view.width+100, @gameboard.view.height+100)    
      setCentralWidget @gameboard.view
    end    
  end
  def setup_menubar
    game = menuBar().addMenu "&Game"
    new_action = Qt::Action.new "&New Game", self
    options_action = Qt::Action.new "&Options", self
    options_action.connect(SIGNAL :triggered) do
      OptionsDialog.new.exec
    end
    quit_action = Qt::Action.new "&Quit", self
    quit_action.connect(SIGNAL :triggered) do 
      Qt::Application.quit
    end 
    game.addAction new_action    
    game.addAction options_action    
    game.addAction quit_action
 
    options = menuBar().addMenu "&Options"
    @paytable_action = Qt::Action.new "Adjust &Paytable", self
    @discard_style_action = Qt::Action.new "Discard Style", self
    @discard_style_action.connect(SIGNAL :triggered) do 
      choose_discard_style
    end
    @discard_style_action.connect(SIGNAL :triggered) do
    end
    @analyzer_action = Qt::Action.new "Analyze &Hands", self
    @analyzer_action.setEnabled false
    menuBar().addAction @analyzer_action
    
    options.addAction @paytable_action
    options.addAction @discard_style_action    
    @paytable_action.setEnabled false
    
    about = menuBar().addMenu "&About"
    about_action = Qt::Action.new "&About", self
    about_action.connect(SIGNAL :triggered) do      
      Qt::MessageBox.information( self, "About","PokerGEMZ. By Joe Hufford. 2013")
    end
    check_updates_action = Qt::Action.new "Check for &Updates", self
    check_updates_action.connect(SIGNAL :triggered) do      
      check_for_updates
    end
    about.addAction check_updates_action
    about.addAction about_action
  end
  def choose_discard_style
    options = @options
    discard_chooser = Qt::Dialog.new(self) do
      setWindowTitle "Choose Discard Style"      
      puts options
      styles = [:move,:flip]
      styles_rb = {}
      #style_group = Qt::GroupBox.new("Discard Style") do
      styles_rb[:flip] = Qt::RadioButton.new("Flip Cards")
      styles_rb[:move] = Qt::RadioButton.new("Move Cards")
      styles.each do |sym|
        styles_rb[sym].connect(SIGNAL :clicked){
          options[:discard_style] = sym
          puts sym.to_s
        }
      end
      styles_rb[options[:discard_style]].setChecked true
      ok_pb = Qt::PushButton.new "Ok"
      ok_pb.connect(SIGNAL :clicked) do
        accept
      end
      layout = Qt::VBoxLayout.new
      styles.each do |rb|
        layout.addWidget styles_rb[rb]
      end
      layout.addWidget ok_pb
      setFixedWidth 200
      setLayout layout
    end
    discard_chooser.exec
  end
  def check_for_updates
    statusBar().showMessage("Checking for updates",2000)    
    Qt::Application.processEvents()    
    require 'open-uri'  
    begin
      version_info = open('https://sites.google.com/site/jahufford/poker/version.txt').read
    rescue
      Qt::MessageBox.information(self, "Error","Couldn't find version.txt file. Internet connection bad?")
      return
    end      
    lines = version_info.lines.to_a
    lines.map!{|line| line.chomp}
    lines = lines.reject{|line| line.empty?}
    version = lines.shift.split('=')[1]        
    if version.to_i > $VERSION      
      msg_box = Qt::MessageBox.new
      msg_box.setWindowTitle "Version"
      msg_box.setText "Newest version is #{version.to_s} and your version is #{$VERSION.to_s}. Perform update?"
      msg_box.addButton Qt::MessageBox::No
      msg_box.addButton Qt::MessageBox::Yes
      response = msg_box.exec
      if response == Qt::MessageBox::Yes
        statusBar().showMessage("Updating",1000)
        Qt::Application.processEvents
        begin          
          lines.each do |line|
            statusBar().showMessage("Downloading #{line}",2000)
            Qt::Application.processEvents
            file_contents = open("https://sites.google.com/site/jahufford/poker/#{line}").read            
            File.open("#{line}.new","w") {|file| file.write file_contents }
          end
          statusBar().showMessage("Files downloaded. Updating local system")
          Qt::Application.processEvents
          lines.each do |line|
            puts "Attemping to delete #{line}"                       
            File.delete(line)
            puts "Attemping to rename #{line}.new to #{line}"
            File.rename("#{line}.new",line)            
          end          
          Qt::MessageBox.information(self, "", "Finished Updating. Please restart program.")
        rescue => e
          puts e.message
          Qt::MessageBox.information(self, "Error","Couldn't finish update.")
        end
      else
        puts "Proceeding with old version"
      end
    else
      Qt::MessageBox.information(self, "","You're up to date!")
    end
  end
end

Qt::Application.new(ARGV) do
  mainwindow = MainWindow.new  
  mainwindow.show
  exec
end

