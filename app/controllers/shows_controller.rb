class ShowsController < ApplicationController
  before_action :set_show, only: %i[show languages]

  # GET /shows or /shows.json
  def index
    @q = Show.active.ransack(params[:q])
    @pagy, @all_shows = pagy(@q.result(distinct: true), items: 20)

    # OPTIMIZE: checkbox filter form
    return unless params[:booking_available] == '1'

    @all_shows = @all_shows.joins(:screenings).distinct
  end

  # GET /shows/1 or /shows/1.json
  def show
    @feedback = @show.feedbacks.new

    # FIXME: change includes order & use async_count
    @reviews_count = @show.feedbacks.count
    @pagy, @show_feedbacks = pagy(@show.feedbacks.order(created_at: :desc).includes(:user))

    @user_has_feedback = @show.feedbacks.find_by(user_id: current_user&.id)
    @user_has_booked = current_user&.user_has_booked?(@show)
  end

  def languages
    render json: @show.languages
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_show
    @show = Show.friendly.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def show_params
    params.require(:show).permit(:name, :description, :poster, :cast, :category, :imdb_rating,
                                 :price, :status, :duration, :release_date, languages: [], genres: [])
  end
end
