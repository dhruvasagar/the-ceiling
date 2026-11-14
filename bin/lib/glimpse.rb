# Build the "A glimpse" slide's table from the two glimpse captures.
#   ruby bin/lib/glimpse.rb captures/glimpse-yjit.txt captures/glimpse-zjit.txt
# Prints one org table row per g_* method in src/glimpse.rb.
#
# What is counted, for each one-line g_* method:
#   YJIT: calls into Ruby methods (methods YJIT compiled blocks for) that
#         push a frame: "real calls". A call YJIT marks "inlined" is counted
#         as inlined. Calls into C are not counted under either compiler.
#   ZJIT: Ruby methods spliced into the caller (PushInlineFrame), and Ruby
#         methods still called (Send*). A body reduced to a constant is
#         reported as folded.
# A Ruby method is one YJIT compiled blocks for in an activesupport file.

yjit_file, zjit_file = ARGV
abort "usage: glimpse.rb YJIT_CAPTURE ZJIT_CAPTURE" unless yjit_file && zjit_file

ROWS = [
  ["g_params",    "params[:name].present?"],
  ["g_presence",  "name.presence"],
  ["g_squish",    "text.squish"],
  ["g_second",    "list.second"],
  ["g_minutes",   "5.minutes"],
  ["g_try",       "obj.try(:upcase)"],
  ["g_nil_blank", "nil.blank?"],
].freeze

# --- YJIT: blocks per method, and the calls inside them -------------------
Block = Struct.new(:meth, :file, :calls)   # calls: [[target, how]]
blocks = []
cur = nil
pending = nil
finish_call = -> { (cur.calls << pending; pending = nil) if cur && pending }
File.foreach(yjit_file) do |l|
  if l =~ /# Block: (\S+?)@(\S+?):\d+/
    finish_call.()
    cur = Block.new($1, $2, [])
    blocks << cur
  elsif cur && l =~ /# call to (\S+)/
    finish_call.()
    pending = [$1, :unknown]
  elsif pending && l.include?("inlined")
    pending[1] = :inlined if pending[1] == :unknown
  elsif pending && l.include?("push callee control frame")
    pending[1] = :frame if pending[1] == :unknown
  elsif pending && l =~ /# Insn:/
    finish_call.()
  end
end
finish_call.()

ruby_names = blocks.select { |b| b.file.include?("active_support") }.map(&:meth).uniq
ruby_method = ->(target) { ruby_names.include?(target.split("#", 2).last) }

def yjit_chain(start, blocks, ruby_method)
  real, inlined, seen, queue = [], [], {}, [[start, nil]]
  until queue.empty?
    meth, = queue.shift
    next if seen[meth]
    seen[meth] = true
    blocks.select { |b| b.meth == meth && (b.file.include?("active_support") || b.file.include?("glimpse.rb")) }.each do |b|
      b.calls.each do |target, how|
        next unless ruby_method.(target)
        if how == :inlined then inlined << target
        else real << target; queue << [target.split("#", 2).last, nil]
        end
      end
    end
  end
  [real.uniq, inlined.uniq - real.uniq]
end

# --- ZJIT: the function that holds the g_* method ---------------------------
zlines = File.readlines(zjit_file)
fn_starts = zlines.each_index.select { |i| zlines[i].start_with?("fn ") }
body = ->(i) { zlines[(i + 1)..].take_while { |l| !l.strip.empty? } }

def plural(n, word) = "#{n} #{word}#{n == 1 ? '' : 's'}"

ROWS.each do |meth, label|
  real, y_inl = yjit_chain(meth, blocks, ruby_method)
  host = fn_starts.find { |i| body.(i).any? { |l| l.include?("PushInlineFrame :#{meth},") } } ||
         fn_starts.find { |i| zlines[i].start_with?("fn #{meth}@") }
  abort "glimpse: ZJIT did not compile #{meth}" unless host
  b = body.(host)
  z_inl = b.grep(/PushInlineFrame :(\S+),/) { $1 }.reject { _1 == meth }
  z_calls = b.grep(/= (?:SendDirect|SendWithoutBlockDirect|SendWithoutBlock|Send)\b.*?:(\S+?)[ ,(]/) { $1 }
             .select { |n| ruby_names.include?(n) }
  folded = z_inl.empty? && z_calls.empty? && b.any? { _1 =~ /Const Value\((true|false|nil)\)/ }

  yjit_cell =
    if real.any? then plural(real.size, "call") + (y_inl.any? ? ", #{y_inl.size} inlined" : "")
    elsif y_inl.any? then "inlined"
    else "none"
    end
  zjit_cell =
    if folded then "folded to a constant"
    elsif z_calls.empty? then (z_inl.size == real.size + y_inl.size && z_inl.size > 1 ? (z_inl.size == 2 ? "both inlined" : "all #{z_inl.size} inlined") : "#{z_inl.size} inlined")
    elsif z_inl.empty? then plural(z_calls.size, "call") + " (not inlined)"
    else "#{z_inl.size} inlined, #{plural(z_calls.size, 'call')}"
    end
  puts "| =#{label}= | #{yjit_cell} | #{zjit_cell} |"
end
