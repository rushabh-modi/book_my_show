class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :theater_admins, dependent: :destroy
  has_many :theaters, through: :theater_admins

  has_many :bookings, dependent: :destroy
  has_many :feedbacks, dependent: :destroy

  validates :name, presence: true

  def send_admin_invitation_email
    raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
    token = raw
    self.reset_password_token = hashed
    self.reset_password_sent_at = Time.now.utc
    self.save
    AdminMailer.admin_invitation(self, token).deliver_later
  end

  def past_bookings
    bookings.past
  end

  def upcoming_bookings
    bookings.upcoming
  end

  def cancelled_bookings
    bookings.cancelled
  end

  def user_has_booked?(show)
    bookings.confirmed.joins(screening: :show).where(screenings: { show: show }).exists?
  end

  def has_booked_in_theater?(theater)
    bookings.confirmed.joins(screening: { screen: :theater }).where(screens: { theater: theater }).exists?
  end
end
