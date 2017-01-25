module WeekVacationDaysConcern
  extend ActiveSupport::Concern

  included do
    helper_method :week_vacation_days
    def week_vacation_days(user_week)
      (user_week.starts_at..user_week.last_day).map do |date|
        user_week.days.find_or_initialize_by(date: date, user: user)
      end.select(&:vacation?)
    end

    helper_method :week_vacation_ranges
    def week_vacation_ranges
      week_vacation_arr = []
      days = week_vacation_days(user_week)
      return week_vacation_arr if days.size == 0
      days.each do |day|
        week_vacation_arr << day.vacation_range_with_the_same_status.pluck(:date).sort!
      end
      week_vacation_ranges = {}
      week_vacation_arr.uniq.each do |arr|
        key = Day.find_by user: user, date: (arr & days.pluck(:date)).first
        week_vacation_ranges[key] = [arr.first, arr.last].sort.uniq if key
      end
      week_vacation_ranges
    end
  end
end
