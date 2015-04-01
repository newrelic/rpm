# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require File.expand_path('../../../../test_helper.rb', __FILE__)
require 'new_relic/agent/transaction/trace'

class NewRelic::Agent::Transaction::TraceTest < Minitest::Test
  def setup
    freeze_time
    @start_time = Time.now
    @trace = NewRelic::Agent::Transaction::Trace.new(@start_time)
    @trace.root_segment.end_trace(@start_time)
  end

  def test_start_time
    assert_equal @start_time, @trace.start_time
  end

  def test_to_collector_array_contains_start_time
    expected = NewRelic::Helper.time_to_millis(@start_time)
    assert_collector_array_contains(:start_time, expected)
  end

  def test_root_segment
    assert_equal 0.0, @trace.root_segment.entry_timestamp
    assert_equal "ROOT", @trace.root_segment.metric_name
  end

  def test_to_collector_array_contains_root_segment_duration
    @trace.root_segment.end_trace(1)
    assert_collector_array_contains(:duration, 1000)
  end

  def test_to_collector_array_contains_transaction_name
    @trace.transaction_name = 'zork'
    assert_collector_array_contains(:transaction_name, 'zork')
  end

  def test_transaction_name_gets_coerced_into_a_string
    @trace.transaction_name = 1337807
    assert_collector_array_contains(:transaction_name, '1337807')
  end

  def test_to_collector_array_contains_uri
    @trace.uri = 'http://windows95tips.com/'
    assert_collector_array_contains(:uri, 'http://windows95tips.com/')
  end

  def test_uri_gets_coerced_into_a_string
    @trace.uri = 95
    assert_collector_array_contains(:uri, '95')
  end

  def assert_collector_array_contains(key, expected)
    indices = [
      :start_time,
      :duration,
      :transaction_name,
      :uri
    ]

    assert_equal expected, @trace.to_collector_array[indices.index(key)]
  end
end
