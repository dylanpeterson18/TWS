class User < ActiveRecord::Base
  validates :username, :password_digest, :session_token, presence: true

  validates :username, uniqueness: true
	validates :password, length: {minimum: 6}, allow_nil: :true

	after_initialize :ensure_session_token
	before_validation :ensure_session_token_uniqueness

  has_many :lunch_attendees
  has_many :lunches, through: :lunch_attendees, source: :lunch_event
  has_many :hosted_lunches, class_name: "LunchEvent", foreign_key: "host_id",
  primary_key: "id"

  attr_reader :password

  def password= password
		self.password_digest = BCrypt::Password.create(password)
		@password = password
	end

  def self.find_by_credentials username, password
		user = User.find_by(username: username)
		return nil unless user
		user.password_is?(password) ? user : nil
	end

	def password_is? password
		BCrypt::Password.new(self.password_digest).is_password?(password)
	end

	def reset_session_token!
		self.session_token = new_session_token
		ensure_session_token_uniqueness
		self.save
		self.session_token
	end

  private

  def ensure_session_token
    self.session_token ||= new_session_token
  end

  def new_session_token
    SecureRandom.base64
  end

  def ensure_session_token_uniqueness
    while User.find_by(session_token: self.session_token)
      self.session_token = new_session_token
    end
  end

end
