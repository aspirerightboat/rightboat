module BrokerArea
  class IframesController < CommonController
    skip_before_action :require_broker_user, only: [:iframe_content]
    after_action :allow_iframe, only: :iframe_content

    def index
      @iframes = current_broker.broker_iframes.page(params[:page]).per(30)
    end

    def new
      @iframe = current_broker.broker_iframes.new
    end

    def create
      @iframe = current_broker.broker_iframes.new(iframe_params)
      assign_filter_params

      if @iframe.save
        redirect_to broker_area_iframe_path(@iframe)
      else
        flash.now.alert = @iframe.errors.full_messages.join(', ')
        render :edit
      end
    end

    def edit
      load_iframe

      if (manufacturer_ids = @iframe.filters[:manufacturer_ids])
        @manufacturer_items = Manufacturer.where(id: manufacturer_ids).pluck_h(:id, :name)
      end

      @country_ids = @iframe.filters[:country_ids]
    end

    def show
      load_iframe
    end

    def update
      load_iframe
      @iframe.assign_attributes(iframe_params)
      assign_filter_params

      if @iframe.save
        redirect_to broker_area_iframe_path(@iframe)
      else
        flash.now.alert = @iframe.errors.full_messages.join(', ')
        render :edit
      end
    end

    def destroy
      load_iframe

      @iframe.destroy
      redirect_to broker_area_iframes_path, notice: 'IFrame deleted successfully.'
    end

    def iframe_content
      load_iframe_from_token
      @boats = @iframe.filtered_boats.active.boat_view_includes.includes(:country).page(params[:page]).per(6 * 3)
      render layout: 'broker_iframe'
    end

    private

    def iframe_params
      params.require(:broker_iframe).permit(:user_boats_only, :items_layout)
    end

    def load_iframe
      @iframe = current_broker.broker_iframes.find(params[:id])
    end

    def load_iframe_from_token
      @iframe = BrokerIframe.find_by!(token: params[:token])
    end

    def assign_filter_params
      @iframe.filters = {
          manufacturer_ids: params[:manufacturers].split('-'),
          country_ids: params[:countries],
      }
    end

    def allow_iframe
      response.headers.delete('X-Frame-Options')
    end
  end
end
