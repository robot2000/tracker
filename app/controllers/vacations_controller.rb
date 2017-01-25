class VacationsController < ApplicationController

  def index; end

  private

  helper_method :selected_users
  def selected_users
    @selected_users ||=
      begin
        users = User.all
        users = users.by_ids(params[:users].split(',')) if params[:users]
        users
      end
  end

  helper_method :dates
  def dates
    @dates ||= generate_monthes(vacations_checked_date).to_a
  end

  helper_method :calendar_preparer
  def calendar_preparer
    @calendar_preparer ||= CalendarPreparer.new(dates, selected_users)
  end

  helper_method :vacation_dates
  def vacation_dates
    @vacation_dates ||= calendar_preparer.generate_dates
  end

  helper_method :vacations_checked_date
  def vacations_checked_date
    @vacations_checked_date ||= params[:date]&.to_date || Date.today
  end
end
