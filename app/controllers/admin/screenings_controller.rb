class Admin::ScreeningsController < Admin::BaseController
  before_action :set_theater
  before_action :set_screen
  before_action :set_screening, only: %i[show edit update destroy]
  before_action :set_show, only: %i[show edit update destroy]
  before_action :get_event_requested_shows, only: %i[new edit]

  def index
    @screenings = @screen.screenings.includes(show: [poster_attachment: :blob]).where(shows: { status: :active })
  end

  def new
    @screening = Screening.new
    @screening.show_timings.build
  end

  def create
    @screening = Screening.new(screening_params)
    authorize @screening

    if @screening.save
      RecurringScreeningsJob.perform_async(@screening.id)
      redirect_to admin_screen_screenings_path(@screen), notice: 'Screening was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    authorize @screening

    if @screening.update(screening_params)
      redirect_to admin_screen_screening_url(@screen, @screening), notice: 'Screening was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @pagy, @show_timings = pagy(@screening.show_timings.order(at_timeof: :asc), items: 6)
  end

  def destroy
    authorize @screening

    @screening.destroy!
    redirect_to admin_screen_screenings_url(@screen), notice: 'Screening was successfully destroyed.'
  end

  private

  def get_event_requested_shows
    event_requested_shows = EventRequest.where(theater: @theater).pluck(:name)
    shows = Show.where(name: event_requested_shows)
    @available_shows = Show.available + shows
  end

  def set_theater
    if session[:current_theater]
      @theater = current_user.theaters.find_by(id: session[:current_theater])
      redirect_to root_path, alert: 'Selected theater not found or you do not have access.' unless @theater
    else
      @theater = current_user.theaters.first
      session[:current_theater] = @theater.id if @theater
    end
  end

  def set_screen
    @screen = Screen.find(params[:screen_id])
  end

  def set_screening
    @screening = Screening.find(params[:id])
  end

  def set_show
    @show = Show.find(@screening.show_id)
  end

  def screening_params
    params.require(:screening).permit(:show_id, :language, :price, :start_date, :end_date,
                                      show_timings_attributes: %i[id at_timeof seats _destroy]).merge(screen_id: @screen.id)
  end
end
