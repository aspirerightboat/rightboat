class BatchUploadJobsController < ApplicationController
  def show
    @job = BatchUploadJob.find_by(id: params[:id])
    if @job.present?
      render json: @job
    else
      render json: { error: @job.errors.full_messages.join('. ') }, status: :not_found
    end
  end
end
