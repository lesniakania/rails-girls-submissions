class SettingsController < ApplicationController
  layout 'admin'

  def index
    settings = Setting.get
    render :index, locals: { settings: settings }
  end

  def update
    if dates_order_ok?(setting_params)
      Setting.set(setting_params)
      redirect_to :back, notice: "Settings are updated"
    else
      redirect_to :back, notice: "Registration start must be after preparation start and before closed start"
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:available_spots, :required_rates_num, :days_to_confirm_invitation,
      :beginning_of_preparation_period, :beginning_of_registration_period, :beginning_of_closed_period,
      :event_start_date, :event_end_date, :event_url, :event_venue)
  end

  def dates_order_ok?(params)
    params[:beginning_of_preparation_period] < params[:beginning_of_registration_period] &&
    params[:beginning_of_registration_period] < params[:beginning_of_closed_period] &&
    params[:event_start_date] < params[:event_end_date]
  end
end
