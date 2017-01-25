require_relative '../general_page'
require_relative '../time_table/day_item'
require_relative '../time_table/confirm'
require_relative '../time_table/modal_approve'
require_relative '../time_table/modal_comment'

module UserWeeks
  class ShowPage < ::GeneralPage
    set_url 'users/{user_id}/user_weeks/{id}'

    element :day, '.dashboard-item'
    element :current_day, '.dashboard-item_today'
    element :close_button, 'a', text: 'Close'
    element :reopen_button, 'a', text: 'Reopen'
    element :user_name, '.week-user__name'
    element :user_week_date, '.week-user__date'
    element :current_week_duration, '.week-time'
    element :fact_week_duration, '.week-time__fact'
    element :vacations_log, '.vacations_log'
    element :roles, 'a[href="#position"]'
    element :previous_week, '.week-nav__item_prev'
    element :next_week, '.week-nav__item_next'
    element :cancel_week, '.week-nav__item_close'
    element :load_spinner, '#loadSpinner'
    elements :vacation_log_item, '.timeupdate-days'
    elements :vacation_log_item_date, '.timeupdate-item-text__time'
    elements :vacation_log_item_owner, '.timeupdate-item-text__name'
    elements :vacation_log_item_pending,  '.timeupdate-item-text__vacation'
    elements :vacation_log_item_approved, '.timeupdate-item-text__vacation_approved'
    elements :vacation_approved, '.ddashboard-item__vacation-status_approved'
    elements :vacation_not_approved, '.dashboard-item__vacation-status_not-approved'
    elements :log_week_duration, '.log_duration'
    elements :office_users, '#office .sidebar-collapse-dropdown-item'
    elements :roles_users, '#position .sidebar-collapse-dropdown-item'

    sections :days, TimeTable::DayItem, '.dashboard-item'
    sections :weekends, TimeTable::DayItem, '.dashboard-item_weekend'
    section :confirm, TimeTable::Confirm, '#confirm'
    section :modal_approve, TimeTable::ModalApprove, '#approve'
    section :modal_comment, TimeTable::ModalComment, '#comment'

    def set_new_time range
      days.first.edit.click
      self.wait_until_load_spinner_visible
      self.wait_until_load_spinner_invisible
      days.first.ranges_to_edit.first.set(range)
      days.first.save.click
      self.wait_until_load_spinner_visible
      self.wait_until_load_spinner_invisible
    end
  end
end
