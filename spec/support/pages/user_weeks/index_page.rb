require_relative '../general_page'
require_relative '../time_table/day_item'

module UserWeeks
  class IndexPage < ::GeneralPage
    set_url 'users/{user_id}/user_weeks'

    element  :user_full_name, '.dashboard__title'
    element  :prev_week,      '[data-weeks="prev"]'
    element  :next_week,      '[data-weeks="next"]'

    element  :half_year, 'a', text: 'Half year'
    element  :year,      'a', text: 'Year'

    element  :load_spinner, '#loadSpinner'
    element  :roles,        'a[href="#position"]'
    element  :day_number,   '.userdays-item__number'
    elements :fact_time,    '.userdays-item__facttime'
    elements :office_users, '#office .sidebar-collapse-dropdown-item'
    elements :roles_users,  '#position .sidebar-collapse-dropdown-item'
    elements :days,         'li.userdays-item'
  end
end
