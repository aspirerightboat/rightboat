class FeedbacksController < ApplicationController

  # def create
  #   @feedback = Feedback.new(feedback_params)
  #
  #   if @feedback.valid?
  #     ContactMailer.new_request(@feedback).deliver_now
  #     render json: {}, status: 200
  #   else
  #     render json: @feedback.errors.full_messages, root: false, status: 422
  #   end
  # end
  #
  # private
  #
  # def feedback_params
  #   params.fetch(:feedback, {})
  #     .permit(:first_name, :last_name, :email, :title, :phone_number, :comments)
  # end
end
