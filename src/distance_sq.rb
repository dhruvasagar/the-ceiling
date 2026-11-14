class Point
  attr_reader :x, :y
  def initialize(x, y) = (@x, @y = x, y)
end

def sq(n) = n * n

def distance(a, b)
  dx = a.x - b.x
  dy = a.y - b.y
  Math.sqrt(sq(dx) + sq(dy))
end

a = Point.new(3, 4)
b = Point.new(0, 0)
1_000.times { distance(a, b) }
