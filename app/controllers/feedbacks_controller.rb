class FeedbacksController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_commentable
  before_action :set_feedback, only: %i[edit update destroy]

  # OPTIMIZE: merge user through params
  def create
    @feedback = @commentable.feedbacks.new(feedback_params)
    @feedback.user = current_user
    authorize @feedback

    respond_to do |format|
      if @feedback.save
        format.html { redirect_to @commentable }
      else
        flash[:alert] = 'All fields are required'
        format.html { render @commentable, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @feedback
  end

  # OPTIMIZE: turbo stream
  def update
    authorize @feedback
    respond_to do |format|
      if @feedback.update(feedback_params)
        format.turbo_stream
        format.html { redirect_to @commentable }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@feedback), partial: 'feedbacks/form',
                                                                       locals: { commentable: @commentable, feedback: @feedback })
        end
      end
    end
  end

  def destroy
    authorize @feedback
    @feedback.destroy

    respond_to do |format|
      format.html { redirect_to @commentable }
      format.turbo_stream
    end
  end

  private

  def feedback_params
    params.require(:feedback).permit(:comment, :rating, :commentable_id, :commentable_type)
  end

  def set_commentable
    @commentable = params[:show_id] ? Show.friendly.find(params[:show_id]) : Theater.friendly.find(params[:theater_id])
  end

  def set_feedback
    @feedback = @commentable.feedbacks.find(params[:id])
  end
end
