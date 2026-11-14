require "active_support"
require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/string/filters"
require "active_support/core_ext/array/access"
require "active_support/core_ext/numeric/time"

def g_params(params) = params[:name].present?
def g_presence(name) = name.presence
def g_squish(text) = text.squish
def g_second(list) = list.second
def g_minutes(n) = n.minutes
def g_try(obj) = obj.try(:upcase)
def g_nil_blank(value) = value.blank?

params = ActiveSupport::HashWithIndifferentAccess.new("name" => "dhruva")
100_000.times { g_params(params) }
100_000.times { g_presence("dhruva") }
100_000.times { g_squish("  hello   world  ") }
100_000.times { g_second([1, 2, 3]) }
100_000.times { g_minutes(5) }
100_000.times { g_try("dhruva") }
100_000.times { g_nil_blank(nil) }
