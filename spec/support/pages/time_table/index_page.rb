require_relative '../general_page'
require_relative './day_item'
require_relative './week_item'
require_relative './confirm'
require_relative './modal_approve'
require_relative './modal_comment'

module TimeTable
  class IndexPage < GeneralPage
    set_url 'users/{user_id}/time_tables'

    sections :days, DayItem, '.dashboard-item'
    sections :weekends, DayItem, '.dashboard-item_weekend'
    sections :holidays, DayItem, '.dashboard-item_holiday'
    sections :weeks, WeekItem, '.dashboard-week'
    section :confirm, Confirm, '#confirm'
    section :modal_approve, ModalApprove, '#approve'
    section :modal_comment, ModalComment, '#comment'
    sections :day_with_crossed_vacations, DayItem, '.dashboard-item_crossed_vacation'
    sections :vacation_days, DayItem, '.dashboard-item_vacation'
    elements :appoved_vacation_days, '.dashboard-item_approved'
    elements :work_days, '.dashboard-item_workday'
    element :hint, '.gumhint'
  end
end
