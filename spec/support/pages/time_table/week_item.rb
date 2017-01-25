module TimeTable
  class WeekItem < ::SitePrism::Section
    elements :days, '.dashboard-item'
  end
end
