require_relative '../general_page'
require_relative './day_item'

module Vacations
  class ShowPage < ::GeneralPage
    set_url 'vacations'

    element  :office_tab, 'a[href="#office"]'
    element  :office_dnepr, 'span[data-name="dnepr"]'
    element  :datepicker, '.datepicker'
    element  :sidebar_avatar, '.sidebar-title__img'
    element  :loadSpinner, '#loadSpinner'
    elements :calendar_day, '.calendar__day'
    elements :approve_vacations, '.holiday-line_approved'
    elements :pending_vacations, '.holiday-line_pending'
    sections :dates, DayItem, '.calendar__item'
  end
end
