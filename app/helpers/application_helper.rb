module ApplicationHelper
  CALENDAR_WEEKS_COUNT = 57

  def class_for_sidebar_dropdown_item user
    klass = 'sidebar-collapse-dropdown-item'
    klass += ' active' if params[:users]&.include?(user.id.to_s)
    klass += ' sidebar-collapse-dropdown-item_pending' if users_with_pending_status.include? user.id
    klass
  end

  def nav_item name, path, options = {:class => 'header-menu__link'}
    link_to name, path, class: (current_page?(path) ? options[:class] + ' active' : options[:class])
  end

  def generate_vacation_day_classes_for date
    if date.weekend?
      'calendar__day_weekend'
    elsif current_user.holiday? date
      'calendar__day_holiday'
    else
      ''
    end
  end

  def class_for_calendar_item date
    klass = 'calendar__item'
    klass += ' calendar__item_today' if date == Date.today
    klass += ' calendar__item_holiday' if current_user.holiday? date
    klass
  end

  def generate_vacation_day_status day
    if day.approved_vacation?
      'holiday-line_approved'
    elsif day.not_approved_vacation?
      'holiday-line_pending'
    end
  end

  def sum_generate_vacation_day_status day
    klass = 'holiday-line-sum'
    if day.approved_vacation?
      klass += ' holiday-line_approved holiday-line_approved-sum'
    elsif day.not_approved_vacation?
      klass += ' holiday-line_pending holiday-line_pending-sum'
    end
    klass
  end

  # def class_for_user_week version
  #   klass = 'audit-content-highlight' if version.whodunnit.to_i != user.id
  # end

  def class_vacation_status day
    klass = 'dashboard-item__vacation-status vacation__trigger'
    klass += ' dashboard-item__vacation-status_clear button__dash_hidden' if day.work_day? || day.cleared_day?
    klass += ' dashboard-item__vacation-status_not-approved' if day.not_approved_vacation?
    klass += ' dashboard-item__vacation-status_approved' if day.approved_vacation?
    klass
  end

  def class_for_work_times_date day
    date = day.date
    klass = 'dashboard-item'
    klass += ' dashboard-item_today'   if date == Date.today
    klass += ' dashboard-item_weekend' if date.weekend?
    klass += ' dashboard-item_holiday' if user.holiday? date
    return klass unless day.present?
    klass += ' dashboard-item_workday'  if day.work_day?
    klass += ' dashboard-item_vacation' if day.not_approved_vacation?
    klass += ' dashboard-item_approved' if day.approved_vacation?
    klass += ' dashboard-item_crossed_vacation' if available_vacation? day
    klass += ' dashboard-item_closed' if day.user_week&.closed?
    klass
  end

  def class_for_audit versions_pair
    klass = ' '
    klass += 'audit-content-highlight' if versions_pair.first.whodunnit != subject_day(versions_pair).user.id.to_s
    klass
  end

  def diff_who_changed versions_pair
    if versions_pair.first.whodunnit == current_user.id.to_s
      'changes were done by you'
    elsif versions_pair.first.whodunnit == subject_day(versions_pair).user.id.to_s
      'changes were done by himself'
    else
      changed_by(versions_pair.first.whodunnit)
    end
  end

  def available_vacation? day
    !(allowed_vacation?(day) || day.work_day? || day.date.weekend? || user.holiday?(day.date)) && (day.not_approved_vacation? || day.approved_vacation?)
  end

  def allowed_vacation? day
    return true if user.not_limited_position?
    vacations = vacations_for(user.position)[day.date]
    vacations ? vacations.count <= 2 : true
  end

  def vacations_for position
    @vacations ||= Day.vacations_for position
  end

  def weeks_mondays
    arr = []
    CALENDAR_WEEKS_COUNT.times { |i| arr << (Date.today.beginning_of_week + i.week) }
    Kaminari.paginate_array(arr).page(params[:page]).per(1)
  end

  def changed_by user_id
    user_id.nil? ? user.full_name : User.find_by(id: user_id)&.full_name
  end

  def whodunnit version
    user_id = version.whodunnit || YAML.load(version.object)['user_id']
    User.find_by(id: user_id)
  end

  def who_changed_user version
    changed_by(version.whodunnit) if version.whodunnit.to_i != user.id
  end

  def subject_day versions
    versions.first.item
  end

  def confirm_to name, path, classes, text, condition, gumhint = nil, method = :get
    if condition
      content_tag :div, name, class: classes + ' confirm_trigger',
                  data: { href: path, method: method, remote: true,
                          confirm: "#{ t(text, user_full_name: user.full_name)}",
                          gumhint: gumhint
                        }
    else
      link_to name, path, remote: true, class: classes, data: { gumhint: gumhint }, method: method
    end
  end

  def confirm_link_to_vacation name, text, condition, day, gumhint = t(:create_vacation)
    confirm_to name, user_day_vacation_request_path(user, day.date),
                     class_vacation_status(day), text, condition, gumhint, :put
  end

  def filter_tag group, users
    has_pending = users.any? { |user| users_with_pending_status.include? user.id }
    content_tag :span, "#{group.name.presence} #{users.count}", class: generate_link_classes_for(has_pending), data: { name: group.code }
  end

  def generate_link_classes_for has_pending
    klass = 'sidebar-collapse-item__link'
    klass = 'sidebar-collapse-item__nolink' if current_path.match(/user_weeks/)
    klass += ' sidebar-collapse-item__link_pending' if has_pending
    klass
  end

  def current_path
    request.env['PATH_INFO']
  end

  def modal_window_title day
    day.not_approved_vacation? ? 'Approve...?' : 'Unapprove...?'
  end

  def edit_another_vacation user, day
    if current_user != user
      state = day.not_approved_vacation? ? 'approve' : 'unapprove'
      'Are you sure you want to ' + state +  " the vacation for #{user.full_name}?"
    end
  end

  def vacation_ranger
    "#{l(vacation_days.first.date, format: :date_month_year)} to #{l(vacation_days.last.date, format: :date_month_year)}"
  end

  def submit_tag_name day
    state = day.not_approved_vacation? ? 'Approve' : 'Unapprove'
    submit_tag state, class: 'modal__footer-btn modal-form__btn'
  end

  def approve_one_or_all_days day
    if day.date < Date.today || day.vacation_range.size == 1
      link_to '', user_day_status_path(user, day.date), remote: true, method: :put,
                  class: class_vacation_status(day), data: { gumhint: vacation_hint(day) }
    else
      link_to '', edit_user_day_status_path(user, day.date), remote: true,
                  class: class_vacation_status(day), data: { gumhint: vacation_hint(day) }
    end
  end

  def sortable column, title = nil
    content_tag :span, title || column, class: 'forecast-sortable forecast-sortable_asc', data: { direction: 'asc', column: column }
  end
end
