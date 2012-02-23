class KeywordCategory
  include Mongoid::Document
  field :title, :type => String
  field :sorted_keywords, :type => String
  field :index_at, :type => Integer

  index :title
  index :index_at

  has_and_belongs_to_many :keywords
  cache

  def ordered_keywords
      match_keywords = []
      diff_keywords = []
      tmp_keywords = self.keywords.to_a
      self.sorted_keywords.split(",").each do |key|
        tmp_keywords.each do |keyword|
          if key == keyword.id.to_s
            match_keywords.push(keyword)
            break
          end
        end
      end if !self.sorted_keywords.blank?
      diff_keywords = tmp_keywords - match_keywords
      return match_keywords + diff_keywords
  end
end
