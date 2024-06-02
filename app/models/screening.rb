class Screening < ApplicationRecord
  belongs_to :screen
  belongs_to :show
  
  after_save :update_screen_status
  after_destroy :update_screen_status
  
  validates :price, :start_date, :end_date, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :start_date_before_end_date
  validate :no_overlapping_screenings
  validate :prohibit_screening_by_screen_status

  private

  def start_date_before_end_date
    if start_date >= end_date
      errors.add(:start_date, 'must be before the end date')
    end
  end

  def no_overlapping_screenings
    overlapping_screenings = Screening.where(screen_id: self.screen_id)
                                      .where.not(id: self.id)
                                      .where('start_date < ? AND end_date > ?', self.end_date, self.start_date)
    
    if overlapping_screenings.exists?
      errors.add(:base, 'This screen is already booked for the selected date range')
    end
  end

  def prohibit_screening_by_screen_status
    if screen.in_maintenance? || screen.unavailable?
      errors.add(:base, 'Screen is in maintenance or unavailable for new screenings')
    end
  end

  def update_screen_status
    current_time = Time.current

    if screen.screenings.where('start_date <= ? AND end_date >= ?', current_time, current_time).exists?
      screen.update(status: :running)
    else
      screen.update(status: :idle)
    end
  end
end