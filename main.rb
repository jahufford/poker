require 'Qt'
require './mainwindow.rb'


Qt::Application.new(ARGV) do
 # mainwindow = MainWindow.new
  #MainWindow.new.show
  #mainwindow.show
  gameboard = Gameboard.new
  gameboard.view.show
  exec
end

