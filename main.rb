require 'Qt'
require './gameboard.rb'
require './rules.rb'
require './paytables.rb'

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
  # class MyHash
    # attr_accessor :value
    # def initialize value
      # @value = value
    # end
  # end
end

class OptionsDialog < Qt::Dialog
  def initialize
    super
    setWindowTitle "PokerGEMZ Options"
  end
end

class MainMenu < Qt::Widget  
  signals 'selection(QVariant)'
  def initialize
    super    
    jacks_or_betterPB = Qt::PushButton.new "Jacks or Better"
    #connect(jacks_or_betterPB, SIGNAL('clicked()'), self, SLOT('button_clicked()'))    
    jacks_or_betterPB.connect(SIGNAL :clicked) do
      emit selection(RubyVariant.new("jacks_or_better"))
    end
    deuces_wildPB = Qt::PushButton.new "Deuces Wild"
    deuces_wildPB.connect(SIGNAL :clicked) do
      emit selection(RubyVariant.new("deuces_wild"))
    end
    layout = Qt::VBoxLayout.new do
      addStretch
      addWidget jacks_or_betterPB    
      addWidget deuces_wildPB
      addStretch
    end
    setLayout layout
  end  
end
  
class MainWindow < Qt::MainWindow
  slots 'construct_game(QVariant)','show_main_menu()'
  def initialize
    super
    setWindowTitle "PokerGEMZ"
    #gameboard = Gameboard.new
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
    $statusBar = statusBar()
    statusBar.show
    #show_main_menu
    @gameboard = Gameboard.new( DeucesWildScoring,DeucesWildPayTable)
    setCentralWidget @gameboard.view    
    resize(@gameboard.view.width+100, @gameboard.view.height+100)    
  end
  def show_main_menu    
    @gameboard.view.hide unless @gameboard.nil?
    @main_menu = MainMenu.new 
    @main_menu.connect(SIGNAL('selection(QVariant)')) do |game|
      construct_game game.value
    end
    setCentralWidget @main_menu
    #update
    #@main_menu.resize(@gameboard.view.width, @gameboard.view.height)
  end
  def construct_game game
    case game
    when "jacks_or_better"
      rules = JacksOrBetterScoring
      paytable = JacksOrBetterPayTable
      setWindowTitle "PokerGEMZ - Jacks or Better"
    when "deuces_wild"
      rules = DeucesWildScoring
      paytable = DeucesWildPayTable
      setWindowTitle "PokerGEMZ - Deuces Wild"
    end
    @gameboard = Gameboard.new(rules,paytable)
    connect(@gameboard,SIGNAL('quit()'),self,SLOT('show_main_menu()'))
   # @gameboard.connect(SIGNAL('quit()'), self, SLOT('show_main_menu()'))
    resize(@gameboard.view.width+100, @gameboard.view.height+100)    
    setCentralWidget @gameboard.view
  end
end

Qt::Application.new(ARGV) do
  mainwindow = MainWindow.new  
  mainwindow.show
  exec
end

