require 'Qt'
require './gameboard.rb'

class MainWindow < Qt::MainWindow
  def initialize
    super
    setWindowTitle "Spider Solitaire"
    # setup_menubar
    # setBaseSize 800, 600
     setMinimumSize 800,600
    new_game
    #setCentralWidget @gameboard.view 
  end
  def new_game
    @gameboard = Gameboard.new
    setCentralWidget @gameboard.view
  end
  def setup_menubar
    game_menu = menuBar.addMenu "&Game"
    new_action = Qt::Action.new "&New Deal", self
    save_action = Qt::Action.new "&Save", self
    quit_action = Qt::Action.new "&Quit", self
    
    game_menu.addAction new_action
    game_menu.addAction save_action
    game_menu.addAction quit_action
    
    help_menu = menuBar.addMenu "&Help"
    rules_action = Qt::Action.new "Rules", self
    about_action = Qt::Action.new "About", self
    
    help_menu.addAction rules_action
    help_menu.addAction about_action
    
    new_action.connect(SIGNAL :triggered) do
      puts "new"      
    end    
    save_action.connect(SIGNAL :triggered) do
      puts "save"
    end
    quit_action.connect(SIGNAL :triggered) do
      Qt::Application.instance.quit
    end
    rules_action.connect(SIGNAL :triggered) do
      puts "rules"      
    end
    about_action
  end
end