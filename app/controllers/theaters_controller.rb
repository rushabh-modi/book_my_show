class TheatersController < ApplicationController
  before_action :set_theater, only: %i[show]

  # GET /theaters or /theaters.json
  def index
    @pagy, @theaters = pagy(Theater.active)
  end

  # GET /theaters/1 or /theaters/1.json
  def show
    # TODO: add below both in concern
    @theater_shows = Show.active.joins(screenings: :screen).where(screens: { theater_id: @theater.id }).distinct

    @show_screening_details = @theater_shows.map do |show|
      screenings = show.screenings.includes(:screen).where(screens: { theater_id: @theater.id })
      { show:, screenings: }
    end

    @feedback = @theater.feedbacks.new
    # FIXME: change includes order & use async_count
    @feedbacks_count = @theater.feedbacks.count
    @pagy, @theater_feedbacks = pagy(@theater.feedbacks.order(created_at: :desc).includes(:user))

    @user_has_booked_in_theater = current_user&.has_booked_in_theater?(@theater)
    @user_has_feedback = @theater.feedbacks.find_by(user_id: current_user&.id)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_theater
    @theater = Theater.friendly.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def theater_params
    params.require(:theater).permit(:name, :address)
  end
end
