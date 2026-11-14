def double(x) = x + x

1_000.times { [1, 2.5, "ab", [1], 3r].each { double(_1) } }
