class BatchUploadJobController < ApplicationController
  def show
    @job = BatchUploadJob.find_by(id: params[:id])
    if @job.present?
      render json: @job
    else
      render json: { error: error.message }, status: :not_found
    end
  end
end
