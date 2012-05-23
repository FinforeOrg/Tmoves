class KeywordsAnalyst
  include Sidekiq::Worker
  sidekiq_options :retry => false
  
  def perform(keywords_str="", created_at=nil, follower=0)
    Finforenet::Workers::AnalyzeKeywords.new(keywords_str, created_at, follower)
  end
end
