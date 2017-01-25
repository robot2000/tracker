describe 'User Week page', type: :feature, js: true do
  include UserWeekHelper

  let(:user) { create(:identity, :dnepr, :pm, email: 'xxx@anadeainc.com').user }
  let(:another_user) { create(:identity, :dnepr, :developer, email: 'yyy@anadeainc.com').user }
  let(:user_week) { create :user_week, user: user, starts_at: Date.today.beginning_of_week }
  let(:work_days) { user_week.work_days_count }
  let(:default_week_duration) { user.schedule.calculate_default_week_duration(work_days) }
  let(:another_user_week) { create :user_week, user: another_user }
  let(:first_week_day) { l Date.today.beginning_of_week, format: :weekday_short }
  let(:last_week_day)  { l(Date.today.beginning_of_week + 6.day, format: :weekday_short) }
  let(:show_page)  { UserWeeks::ShowPage.new }
  let(:index_page) { UserWeeks::IndexPage.new }

  before do
    allow(PositionService).to receive(:position_by).with(user.email).        and_return(:pm)
    allow(PositionService).to receive(:position_by).with(another_user.email).and_return(:developer)
    login_as user.identity
    load_show_page user
  end

  before(:all) do
    Timecop.travel('2016/11/28')
  end

  after(:all) do
    Timecop.return
  end

  context 'user week page' do
    it 'should have content' do
      expect(show_page).to have_day
      expect(show_page).to have_content(first_week_day)
      expect(show_page).to have_content(last_week_day)
      show_page.wait_for_current_day
      expect(show_page).to have_current_day
      expect(show_page).to have_close_button
      expect(show_page).to have_current_week_duration
    end

    it 'should not display log, if working time for week equals default work time' do
      show_page.days.first.edit.click
      show_page.days.first.wait_until_save_visible
      show_page.days.first.save.click
      wait_for_ajax
      expect(show_page.fact_week_duration.text).to eq(conversion_week_duration user_week.reload.default_week_duration)
    end

    it 'should display log, if working time for week not equals default work time' do
      show_page.days.first.edit.click
      show_page.days.first.wait_until_save_visible
      show_page.days.first.ranges_to_edit.first.set('06:00 - 12:00')
      show_page.days.first.ranges_to_edit.last.set('13:00 - 20:00')
      show_page.days.first.save.click
      show_page.days.first.wait_until_edit_visible
      expect(show_page).to have_content('45:00')
    end

    it 'should changed the button text when changing status week' do
      show_page.close_button.click
      expect(show_page).to have_reopen_button
      show_page.reopen_button.click
      expect(show_page).to have_close_button
    end

    it 'should show default week duration' do
      expect(show_page).to have_content(default_week_duration / 60)
    end

    it 'should remove intermediate values between the same duration' do
      show_page.set_new_time('06:00 - 12:00')
      show_page.set_new_time('06:00 - 12:01')
      show_page.set_new_time('06:00 - 12:02')
      show_page.set_new_time('06:00 - 12:03')
      show_page.set_new_time('06:00 - 12:00')
      expect(show_page.log_week_duration.count).to eq 1
    end
  end

  context 'log vacations on user week page' do
    it 'should show one vacations_log item on user_week page' do
      show_page.days.first.vacation_clear.click
      expect(show_page.days.first).to have_vacation_day_not_approved
      expect(show_page.vacation_not_approved.count).to eq 1
      expect(show_page.vacations_log).to have_content('Vacations')
      expect(show_page).to have_vacation_log_item_pending
      expect(show_page.vacation_log_item_pending.first).to have_content('DAY OFF')
      expect(show_page).to have_vacation_log_item_date
      expect(show_page.vacation_log_item_date.first).to have_content('Nov 28')
      expect(show_page).to have_vacation_log_item_owner
    end

    it 'should show two vacations_log item without refresh page' do
      show_page.days.first.vacation_clear.click
      show_page.days.first.wait_until_vacation_day_not_approved_visible
      expect(show_page.vacations_log).to have_content('Vacations')
      expect(show_page.vacation_log_item_pending.first).to have_content('DAY OFF')
      expect(show_page.vacation_log_item_date.first).to have_content('Nov 28')
      show_page.days.last.vacation_clear.click
      show_page.confirm.yes_btn.click
      wait_for_ajax
      expect(show_page.vacation_log_item_pending.last).to have_content('APPROVED')
      expect(show_page.vacation_log_item_date.last).to have_content('Dec 4')
    end

    it 'refresh vacation status for vacations_log item without refresh page' do
      show_page.days.first.vacation_clear.click
      show_page.days.first.wait_until_vacation_day_not_approved_visible
      show_page.days.last.vacation_clear.click
      show_page.confirm.yes_btn.click
      wait_for_ajax
      expect(show_page.vacation_log_item_pending.first).to have_content('DAY OFF')
      expect(show_page.vacation_log_item_date.first).to have_content('Nov 28')
      expect(show_page.vacation_log_item_pending.last).to have_content('APPROVED')
      expect(show_page.vacation_log_item_date.last).to have_content('Dec 4')
      show_page.days.first.vacation_day_not_approved.click
      show_page.days.first.wait_until_vacation_day_approved_visible
      expect(show_page.vacation_log_item_pending.first).to have_content('APPROVED')
      expect(show_page.vacation_log_item_date.first).to have_content('Nov 28')
      show_page.days.last.vacation_day_approved.click
      show_page.days.last.wait_until_vacation_day_not_approved_visible
      expect(show_page.vacation_log_item_pending.last).to have_content('DAY OFF')
      expect(show_page.vacation_log_item_date.last).to have_content('Dec 4')
    end

    it 'remove vacation log item from page after clear day' do
      show_page.days.first.vacation_clear.click
      show_page.days.first.wait_until_vacation_day_not_approved_visible
      expect(show_page.vacation_not_approved.count).to eq 1
      expect(show_page.vacation_log_item.count).to eq 1
      expect(show_page.vacation_log_item_pending.first).to have_content('DAY OFF')
      expect(show_page.vacation_log_item_date.first).to have_content('Nov 28')
      show_page.days.first.edit.click
      show_page.days.first.wait_until_ranges_to_edit_visible
      show_page.days.first.clear.click
      show_page.days.first.wait_until_vacation_clear_visible
      expect(show_page.vacation_log_item.count).to eq 0
      expect(show_page).to_not have_vacation_log_item_pending
    end

    it 'should show and refresh comment without refresh page' do
      show_page.days.first.vacation_clear.click
      show_page.days.first.wait_until_vacation_day_not_approved_visible
      show_page.days.first.pencil.click
      show_page.modal_comment.comment_textarea.set 'Comment'
      show_page.modal_comment.save.click
      show_page.days.first.wait_until_comment_icon_visible
      expect(show_page.vacation_log_item_date.last).to have_content('Comment')
      expect(show_page.vacation_log_item_owner.last).to have_content('on Nov 27')
      show_page.days.first.comment_icon.click
      show_page.modal_comment.comment_textarea.set 'Other comment'
      show_page.modal_comment.save.click
      wait_for_ajax
      expect(show_page.vacation_log_item_date.last).to have_content('Other comment')
      expect(show_page.vacation_log_item_owner.last).to have_content('on Nov 27')
    end

    context 'can change user on sidebar' do
      it 'can change other user' do
        expect(show_page.user_name).to have_content(user.full_name)
        expect(show_page).to have_office_users
        show_page.office_users.last.click
        expect(show_page.user_name).to have_content(another_user.full_name)
      end

      it 'can change user with any role' do
        expect(show_page.user_name).to have_content(user.full_name)
        show_page.roles.click
        load_show_page another_user
        expect(show_page.user_name).to have_content(another_user.full_name)
        show_page.roles.click
        show_page.roles_users.first.click
        expect(show_page.user_name).to have_content(user.full_name)
      end
    end
  end

  context 'can change other week with button click' do
    it 'can change previous week' do
      show_page.wait_for_days
      expect(show_page.user_week_date).to have_content('November, 28 - December, 4')
      expect(show_page.days.first.week_day).to have_content('Mon, 28')
      expect(show_page.previous_week).to be_visible
      expect(show_page.next_week).to be_visible
      expect(show_page.cancel_week).to be_visible
      show_page.previous_week.click
      show_page.days.first.wait_until_vacation_clear_visible
      expect(show_page.user_week_date).to have_content('November, 21 - November, 27')
      expect(show_page.days.first.week_day).to have_content('Mon, 21')
    end

    it 'can change next week' do
      show_page.wait_for_days
      expect(show_page.user_week_date).to have_content('November, 28 - December, 4')
      expect(show_page.days.first.week_day).to have_content('Mon, 28')
      show_page.next_week.click
      show_page.days.first.wait_until_vacation_clear_visible
      expect(show_page.user_week_date).to have_content('December, 5 - December, 11')
      expect(show_page.days.first.week_day).to have_content('Mon, 5')
    end

    it 'can delete week from page and redirect to index page' do
      show_page.cancel_week.click
      expect(show_page).to have_no_previous_week
      expect(show_page).to have_no_next_week
      expect(show_page).to have_no_cancel_week
      expect(index_page.fact_time.first).to have_content('40')
    end
  end

  context 'can change user on index page with sidebar' do
    it 'after change another user return to current user can view current user full_name ' do
      show_page.cancel_week.click
      index_page.link_user_weeks.click
      expect(index_page.user_full_name).to have_content(user.full_name)
      index_page.office_users.last.click
      expect(index_page.user_full_name).to have_content(another_user.full_name)
      index_page.link_user_weeks.click
      expect(index_page.user_full_name).to have_content(user.full_name)
    end
  end

  describe 'when user edit not his work_time he have attention confirm' do
    before do
      load_show_page another_user
    end

    it 'should not view default ranges for weekends' do
      show_page.days.first.edit.click
      expect(show_page).to have_content('Are you sure you want to edit the schedule of')
    end
  end

  context 'confirmation' do
    before do
      load_show_page another_user
    end

    context 'edition ranges' do
      it 'should show confirm window' do
        show_page.days.first.edit.click
        expect(show_page.confirm).to be_visible
      end

      it 'should have another user full name in confirm modal' do
        show_page.days.first.edit.click
        expect(show_page.confirm.text).to have_content(another_user.full_name)
      end

      it 'should allow to change ranges after clicking Yes button' do
        show_page.days.first.edit.click
        show_page.confirm.yes_btn.click
        show_page.days.first.wait_until_ranges_to_edit_visible
        expect(show_page.days.first).to have_ranges_to_edit
      end

      it 'should not allow to change ranges after clicking No buttom' do
        show_page.days.first.edit.click
        show_page.confirm.no_btn.click
        show_page.days.first.wait_until_ranges_to_edit_invisible
        expect(show_page.days.first).to_not have_ranges_to_edit
      end
    end

    context 'edition vacation' do
      it 'should show confirm window' do
        show_page.days.first.vacation_clear.click
        expect(show_page.confirm).to be_visible
      end

      it 'should have another user full name in confirm modal' do
        show_page.days.first.vacation_clear.click
        expect(show_page.confirm.text).to have_content(another_user.full_name)
      end

      it 'should not allow to vacation status to request after clicking No button' do
        show_page.days.first.vacation_clear.click
        show_page.confirm.no_btn.click
        show_page.days.first.wait_until_vacation_status_visible
        expect(show_page.days.first).to have_vacation_clear
      end

      it 'should not allow to vacation status to request after clicking No button' do
        show_page.days.first.vacation_clear.click
        show_page.confirm.no_btn.click
        show_page.days.first.wait_until_vacation_clear_visible
        expect(show_page.days.first).to have_vacation_clear
      end
    end

    context 'work day (with ranges)' do
      before do
        show_page.days.first.edit.click
        show_page.confirm.yes_btn.click
        show_page.days.first.save.click
      end

      it 'should show modal confirmation with edition_reject message' do
        show_page.days.first.vacation_clear.click
        expect(show_page.confirm.message.text).to eq(I18n.t(:edition_reject))
      end

      it 'should change day status to not_approved_vacation on Yes button click' do
        show_page.days.first.vacation_clear.click
        show_page.confirm.yes_btn.click
        expect(show_page.days.first).to have_vacation_day_not_approved
      end

      it 'should not change day status on No button click' do
        show_page.days.first.vacation_clear.click
        show_page.confirm.no_btn.click
        expect(show_page.days.first).to_not have_vacation_day_not_approved
        expect(show_page.days.first).to have_vacation_clear
      end
    end

    context 'cleared day on not work day' do
      it 'should show modal confirmation with request_on_holiday message' do
        show_page.weekends.first.vacation_clear.click
        expect(show_page.confirm.message.text).to eq(I18n.t(:request_on_holliday))
      end

      it 'should change day status to approved_vacation on Yes button click' do
        show_page.weekends.first.vacation_clear.click
        show_page.confirm.yes_btn.click
        expect(show_page.weekends.first).to have_vacation_day_approved
      end

      it 'should not change day status on No button click' do
        show_page.weekends.first.vacation_clear.click
        show_page.confirm.no_btn.click
        expect(show_page.weekends.first).to_not have_vacation_day_approved
        expect(show_page.weekends.first).to have_vacation_clear
      end
    end
  end

  def load_show_page user
    show_page.load user_id: user.id, id: Date.today.beginning_of_week.to_s
  end
end
