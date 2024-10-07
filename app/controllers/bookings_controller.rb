class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_screening

  def new
    @booking = @screening.bookings.new
    authorize @booking
  end

  # OPTIMIZE: merge data through params
  def create
    @booking = @screening.bookings.new(booking_params)
    @booking.booking_date = @booking.show_timing&.at_timeof
    @booking.total_price = (@booking.ticket * @booking.screening.price).round(2)
    @booking.user = current_user
    authorize @booking

    if @booking.save
      @booking.send_booking_confirmed_mail
      redirect_to profile_path, notice: 'Booking was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def cancel_booking
    @booking = Booking.find(params[:id])

    if @booking.update(status: :cancelled)
      @booking.send_booking_cancelled_mail
      @booking.increment_seats
      redirect_to profile_path, notice: 'Booking was successfully cancelled.'
    else
      redirect_to profile_path, alert: 'Failed to cancel the booking.'
    end
  end

  private

  def set_screening
    @screening = Screening.find(params[:screening_id])
  end

  def booking_params
    params.require(:booking).permit(:ticket, :booking_date, :total_price, :show_timing_id, :status, :screening_id)
  end
end
