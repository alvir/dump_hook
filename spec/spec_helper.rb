$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dump_hook'

RSpec::Matchers.define_negated_matcher :not_change, :change
