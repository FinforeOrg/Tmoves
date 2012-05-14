class ScannerTask
  include Mongoid::Document
  include Mongoid::Timestamps

  field :keywords,       :type => String
  field :keywords_regex, :type => String
  belongs_to :scanner_account

  validates :keywords, :presence => true, :uniqueness => true
  
  before_create :prepare_creation
  after_create  :after_creation
  
  def prepare_creation
    if self.valid?
      arr_keywords = self.keywords.split(',')
      dictionaries = ""
      arr_keywords.each do |keyword|
        dictionaries += Finforenet::Utils::String.keyword_regex(keyword) + "|"
      end
      self.keywords_regex = dictionaries.gsub(/(^\|)|(\|$)/i,"")
    end
  end
  
  def after_creation
    if self.valid?
      self.scanner_account.update_attribute(:is_used, true)
    end
  end

end
