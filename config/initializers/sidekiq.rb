Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'tmoves' }
end
