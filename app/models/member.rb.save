class Member
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  field :is_subscriber, :type => Boolean, :default => true
  
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  
  validates :password, :confirmation => true, :if => :password_required?

  protected
  def password_required?
	false
  end 
end
