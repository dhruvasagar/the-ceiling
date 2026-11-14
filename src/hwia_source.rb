require "active_support"
require "active_support/hash_with_indifferent_access"

hwia = ActiveSupport::HashWithIndifferentAccess
puts "activesupport #{ActiveSupport.version}"
%i[[] convert_key].each do |name|
  file, line = hwia.instance_method(name).source_location
  src = File.readlines(file)[(line - 1)..]
  puts "", "# #{File.basename(file)}:#{line}", src.take(src.index { _1 =~ /^\s*end\b/ } + 1)
end
