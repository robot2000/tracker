class CalendarPreparer
  attr_accessor :date_range,
                :vacation_dates,
                :previous_step,
                :current_step,
                :duplicates,
                :new_day_state

  def initialize dates, selected_users
    @date_range = dates
    @vacation_dates = Day.for_calendar @date_range, selected_users
    @previous_step = []
    @current_step =  []
    @duplicates =    []
    @new_day_state = []
  end

  def generate_dates
    vacation_dates.each do |date, vacations|
      @previous_step = vacation_dates[check date - 1.day]
      next unless previous_step.present?

      @current_step = vacation_dates[date]
      find_duplicates
      next unless duplicates.present?

      build_new_day
      fill_with_others
      vacation_dates[date] = new_day_state
    end
    vacation_dates
  end

  def check date
    return date if !date.weekend? && !Location.holiday?(date, :ukraine)
    check date - 1.day
  end

  def find_duplicates
    @duplicates = current_step.map do |item|
      item if user_ids(previous_step).include? item&.user_id
    end.compact
  end

  def build_new_day
    @new_day_state = []
    duplicates.each do |item|
      index = user_ids(previous_step).index(item&.user_id)
      new_day_state[index] = item if index.present?
    end
  end

  def fill_with_others
    other = current_step.reject{ |item| user_ids(duplicates).include?(item.user_id) }

    while other.any? do
      index = new_day_state.index(nil)
      if index
        new_day_state[index] = other.pop
      else
        new_day_state << other.pop
      end
    end
  end

  def user_ids relation
    relation.map{ |v| v&.user_id }.to_a
  end
end
