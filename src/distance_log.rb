class Point
  attr_reader :x, :y
  def initialize(x, y) = (@x, @y = x, y)
end

def distance(a, b)
  dx = a.x - b.x
  dy = a.y - b.y
  Math.sqrt(dx * dx + dy * dy)
end

$stdout.sync = true
a = Point.new(3, 4)
b = Point.new(0, 0)
1.upto(40) do |i|
  puts "call #{i}"
  distance(a, b)
end
