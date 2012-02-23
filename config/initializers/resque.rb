require 'resque'
require 'resque_scheduler'

redis_config = YAML.load_file("#{Rails.root}/config/redis.yml")
Resque.redis = redis_config[Rails.env]
Resque.redis.namespace = "stream"
Resque.schedule = YAML.load_file(File.join(File.dirname(__FILE__), '../resque_schedule.yml'))
$redis = Redis.new(:host => 'localhost', :port => 6379)
Dir[File.join(Rails.root, "lib", "finforenet", "**", "*.rb")].sort.each { |lib| require(lib) }
Streaming::Application.middleware.use( Oink::Middleware, :instruments => :memory )
