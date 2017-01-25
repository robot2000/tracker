module Vacations
  class DayItem < ::SitePrism::Section
    elements :users_not_approved, '.holiday-line_pending'
    elements :users_approved,     '.holiday-line_approved'
  end
end
