class Admin::ScreeningsController < Admin::BaseController
  before_action :set_theater
  before_action :set_screen
  before_action :set_screening, only: %i[show edit update destroy]
  before_action :set_show, only: %i[show edit update destroy]

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

    respond_to do |format|
      if @screening.save
        RecurringScreeningsJob.perform_async(@screening.id)
        format.html do
          redirect_to admin_screen_screenings_path(@screen), notice: 'Screening was successfully created.'
        end
        format.json { render :screening, status: :created, location: @screening }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @screening.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    authorize @screening

    respond_to do |format|
      if @screening.update(screening_params)
        format.html do
          redirect_to admin_screen_screening_url(@screen, @screening), notice: 'Screening was successfully updated.'
        end
        format.json { render :screening, status: :ok, location: @screening }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @screening.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @pagy, @show_timings = pagy(@screening.show_timings.order(at_timeof: :asc), items: 6)
  end

  def destroy
    authorize @screening

    @screening.destroy!
    respond_to do |format|
      format.html { redirect_to admin_screen_screenings_url(@screen), notice: 'Screening was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

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
    params.require(:screening).permit(:show_id, :screen_id, :language, :price, :start_date, :end_date,
                                      show_timings_attributes: %i[id at_timeof seats _destroy])
  end
end
