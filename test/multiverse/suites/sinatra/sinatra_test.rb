
class SinatraRouteTestApp < Sinatra::Base
  configure do
    # display exceptions so we see what's going on
    enable :raise_errors
    disable :show_exceptions

    # create a condition (sintra's version of a before_filter) that returns the
    # value that was passed into it.
    set :my_condition do |boolean|
      condition do
        halt 404 unless boolean
      end
    end
  end

  get '/user/login' do
    "please log in"
  end

  # this action will always return 404 because of the condition.
  get '/user/:id', :my_condition => false do |id|
    "Welcome #{id}"
  end

  # check that pass works properly
  condition { pass { halt 418, "I'm a teapot." } }
  get('/pass') { }

  get '/pass' do
    "I'm not a teapot."
  end
end

class SinatraTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ::NewRelic::Agent::Instrumentation::Sinatra

  def app
    SinatraRouteTestApp
  end

  def setup
    ::NewRelic::Agent.manual_start
  end

  # https://support.newrelic.com/tickets/24779
  def test_lower_priority_route_conditions_arent_applied_to_higher_priority_routes
    get '/user/login'
    assert_equal 200, last_response.status
    assert_equal 'please log in', last_response.body
  end

  def test_conditions_are_applied_to_an_action_that_uses_them
    get '/user/1'
    assert_equal 404, last_response.status
  end

  def test_queue_time_headers_are_passed_to_agent
    get '/user/login', {}, {"X-Request-Start" => 't=1234567890'}
    metric_names = ::NewRelic::Agent.agent.stats_engine.stats_hash.keys.map{|k| k.name}
    assert metric_names.include?("Middleware/all")
    assert metric_names.include?("WebFrontend/QueueTime")
    assert metric_names.include?("WebFrontend/WebServer/all")
    assert ::NewRelic::Agent.agent.stats_engine.get_stats("WebFrontend/WebServer/all")
  end

  def test_does_not_break_pass
    get '/pass'
    assert_equal 200, last_response.status
    assert_equal "I'm not a teapot.", last_response.body
  end
end
