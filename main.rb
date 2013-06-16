require 'Qt'
require './gameboard.rb'
#require './mainwindow.rb'


class MainWindow < Qt::MainWindow
  def initialize
    super
    setWindowTitle "PokerGEMZ"
    gameboard = Gameboard.new
    game = menuBar().addMenu "&Game"
    new_action = Qt::Action.new "&New Game", self
    options_action = Qt::Action.new "&Options", self
    quit_action = Qt::Action.new "&Quit", self
    quit_action.connect(SIGNAL :triggered) do 
      Qt::Application.quit
    end 
    game.addAction new_action    
    game.addAction options_action    
    game.addAction quit_action
    $statusBar = statusBar()
    statusBar.show
    setCentralWidget gameboard.view
    resize(gameboard.view.width+100, gameboard.view.height+100)    
  end
end

Qt::Application.new(ARGV) do
  mainwindow = MainWindow.new  
  mainwindow.show
  exec
end

