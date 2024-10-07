class Screening < ApplicationRecord
  belongs_to :screen
  belongs_to :show

  has_many :bookings, dependent: :destroy
  has_many :show_timings, dependent: :destroy

  # OPTIMIZE: status changes
  after_save :update_screen_status
  after_destroy :update_screen_status
  before_create :start_date_before_end_date

  validates :language, :price, :start_date, :end_date, presence: true
  validates :price, numericality: { greater_than: 0 }

  validate :no_overlapping_screenings
  validate :prohibit_screening_by_screen_status

  accepts_nested_attributes_for :show_timings, reject_if: :all_blank, allow_destroy: true

  private

  def start_date_before_end_date
    return unless start_date > end_date

    errors.add(:start_date, 'must be before the end date')
    throw(:abort)
  end

  def no_overlapping_screenings
    overlapping_screenings = Screening.where(screen_id:)
                                      .where.not(id:)
                                      .where('start_date < ? AND end_date > ?', end_date, start_date)

    return unless overlapping_screenings.exists?

    errors.add(:base, 'This screen is already assigned for the selected date range')
  end

  def prohibit_screening_by_screen_status
    return unless screen.in_maintenance? || screen.unavailable?

    errors.add(:base, 'Screen is in maintenance or unavailable for new screenings')
  end

  def update_screen_status
    # OPTIMIZE: use named placeholder for inputs
    if screen.screenings.where('start_date <= ? AND end_date >= ?', Time.current, Time.current).exists?
      screen.update(status: :running)
    else
      screen.update(status: :idle)
    end
  end
end
