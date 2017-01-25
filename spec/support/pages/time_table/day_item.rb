module TimeTable
  class DayItem < ::SitePrism::Section
    element :date, '.dashboard-item__date'
    element :week_day, '.dashboard-item__weekday'
    element :total_time, '.dashboard-item_workday_full-time'
    element :edit, '.button__dash'
    element :cancel, 'a', text: 'Cancel'
    element :save, "input[type='submit']"
    element :clear, 'a', text: 'Clear'
    element :pencil, '.dashboard-item__pencil'
    element :vacation_clear, '.dashboard-item__vacation-status_clear'
    element :vacation_status, '.dashboard-item__vacation-status'
    element :vacation_day_approved, '.dashboard-item__vacation-status_approved'
    element :vacation_day_not_approved, '.dashboard-item__vacation-status_not-approved'
    element :comment_icon, '.dashboard-item__comment'
    elements :default_ranges, '.dashboard-range__item_default'
    elements :ranges, '.dashboard-range__item'
    elements :ranges_to_edit, '.dashboard-range-form__input'
    elements :ranges_with_incorrect_data, '.incorrect'
  end
end
