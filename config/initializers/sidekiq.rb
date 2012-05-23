Sidekiq.configure_server do |config|
  require 'sidekiq/middleware/server/unique_jobs'
  config.redis = { :url => 'redis://localhost:6379/0' }
  config.server_middleware do |chain|
    chain.remove Sidekiq::Middleware::Server::RetryJobs
  end
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::UniqueJobs
  end
end

Sidekiq.configure_client do |config|
  require 'sidekiq/middleware/client/unique_jobs'
  config.redis = { :url => 'redis://localhost:6379/0' }
  config.client_middleware do |chain|
    chain.add Sidekiq::Middleware::Client::UniqueJobs
  end
end
