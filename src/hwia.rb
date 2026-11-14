require "active_support"
require "active_support/hash_with_indifferent_access"

params = ActiveSupport::HashWithIndifferentAccess.new("id" => 1, "name" => "x")
100_000.times do
  params[:id]
  params["name"]
end
