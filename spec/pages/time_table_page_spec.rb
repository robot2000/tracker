shared_examples 'can edit' do
  context 'have edit link' do
    it { expect(item.edit).to have_content('Edit') }
  end
end

describe 'WorkTime', type: :feature, js: true do
  include ApplicationHelper
  let(:user) { create(:identity, :developer).user }
  let(:another_user) { create(:identity, :developer).user }
  let(:holidays) { { ukraine: ['Mon, 02 Jan 2017', 'Mon, 09 Jan 2017', 'Mon, 23 Jan 2017', 'Wed, 08 Mar 2017',
                               'Sun, 16 Apr 2017', 'Mon, 01 May 2017', 'Tue, 02 May 2017', 'Tue, 09 May 2017',
                               'Sun, 04 Jun 2017', 'Wed, 28 Jun 2017', 'Thu, 24 Aug 2017', 'Sat, 14 Oct 2017',
                               'Mon, 01 Jan 2018', 'Mon, 08 Jan 2018', 'Mon, 22 Jan 2018', 'Thu, 08 Mar 2018'],
                    belarus:  ['Mon, 02 Jan 2017', 'Wed, 08 Mar 2017', 'Mon, 01 May 2017', 'Tue, 09 May 2017']} }
  let(:index_page) { TimeTable::IndexPage.new }
  let!(:current_monday) { Date.today.beginning_of_week }
  let(:item) { day_item(Date.today) }

  before do
    allow(PaperTrail).to receive(:whodunnit) { user.id.to_s }
  end

  context 'index' do
    before do
      login_as user.identity
      index_page.load(user_id: user.id)
      wait_for_ajax
    end

    it 'have user name on page' do
      expect(index_page).to have_content(user.full_name)
    end

    it 'render 57 weeks' do
      expect(index_page.days.count).to eq (current_monday...current_monday + 57.weeks).count
    end

    context 'comments' do
      before(:all) { Timecop.travel('2016/12/05') }

      before do
        index_page.days[0].vacation_status.click
        index_page.days[1].vacation_status.click
        index_page.days[2].vacation_status.click
        index_page.days[2].pencil.click
        index_page.wait_until_modal_comment_visible
        index_page.modal_comment.comment_textarea.set('Someting writed')
      end

      it 'should be one comment for a few days' do
        index_page.modal_comment.save.click
        index_page.wait_until_modal_comment_invisible
        index_page.days[0].comment_icon.click
        expect(index_page.modal_comment.comment_textarea).to have_content('Someting writed')
      end

      it 'should be one comment if user selected comment for one day' do
        index_page.modal_comment.current_day_radio_button.click
        index_page.modal_comment.save.click
        index_page.wait_until_modal_comment_visible
        expect(index_page.days[0]).to_not have_comment_icon
        index_page.days[2].comment_icon.click
        expect(index_page.modal_comment.comment_textarea).to have_content('Someting writed')
      end

      after(:all) { Timecop.return }
    end

    context 'first item is correct' do
      it { expect(item.date).to be_visible }
      it { expect(item.date.text).to eq I18n.l(Date.today, format: :mon_day_year) }
    end

    context 'holidays' do
      let!(:holidays_array) { holidays[user.country].select do |item|
                                date = item.to_date
                                date if (current_monday...current_monday + 57.weeks).include?(date)
                              end
                            }

      it 'should view correct holidays count' do
        expect(index_page.holidays.count).to eq holidays_array.count
      end

      it 'should not view default ranges for holidays' do
        expect(index_page.holidays.first).to_not have_ranges
        expect(index_page.holidays.last).to_not have_ranges
      end
    end

    context 'weekends' do
      it 'should view correct weekends count' do
        expect(index_page.weekends.count).to eq Date.weekends_count(current_monday, current_monday + 57.weeks)
      end

      it 'should not view default ranges for weekends' do
        expect(index_page.weekends.first).to_not have_ranges
        expect(index_page.weekends.last).to_not have_ranges
      end
    end

    context 'week' do
      it 'should content 7 days' do
        expect(index_page.weeks.first.days.count).to eq 7
      end
    end
  end

  context 'ability to edition work_time' do
    before do
      login_as user.identity
    end

    describe 'user can edit his work_time' do
      before do
        index_page.load(user_id: user.id)
        wait_for_ajax
      end
      it_behaves_like('can edit')
    end

    describe 'user can edit not his work_time' do
      before do
        index_page.load(user_id: another_user.id)
        wait_for_ajax
      end
      it_behaves_like('can edit')
    end

    describe 'when user edit not his work_time he have attention confirm' do
      before do
        index_page.load(user_id: another_user.id)
        wait_for_ajax
      end

      it 'should not view default ranges for weekends' do
        index_page.days.first.edit.click
        expect(index_page).to have_content('Are you sure you want to edit the schedule of')
      end
    end

    context 'confirmation' do
      before do
        index_page.load(user_id: another_user.id)
        wait_for_ajax
      end

      context 'edition ranges' do
        it 'should show confirm window' do
          index_page.days.first.edit.click
          expect(index_page.confirm).to be_visible
        end

        it 'should have another user full name in confirm modal' do
          index_page.days.first.edit.click
          expect(index_page.confirm.text).to have_content(another_user.full_name)
        end

        it 'should allow to change ranges after clicking Yes button' do
          index_page.days.first.edit.click
          index_page.confirm.yes_btn.click
          index_page.days.first.wait_until_ranges_to_edit_visible
          expect(index_page.days.first).to have_ranges_to_edit
        end

        it 'should not allow to change ranges after clicking No button' do
          index_page.days.first.edit.click
          index_page.confirm.no_btn.click
          index_page.days.first.wait_until_ranges_to_edit_invisible
          expect(index_page.days.first).to_not have_ranges_to_edit
        end
      end

      context 'edition vacation' do
        it 'should show confirm window' do
          index_page.days.first.vacation_clear.click
          expect(index_page.confirm).to be_visible
        end

        it 'should have another user full name in confirm modal' do
          index_page.days.first.vacation_clear.click
          expect(index_page.confirm.text).to have_content(another_user.full_name)
        end

        it 'should allow to change vacation status to request after clicking Yes button' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.yes_btn.click
          index_page.days.first.wait_until_vacation_status_visible
          expect(index_page.days.first).to have_vacation_status
        end

        it 'should not allow to vacation status to request after clicking No button' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.no_btn.click
          index_page.days.first.wait_until_vacation_clear_visible
          expect(index_page.days.first).to have_vacation_clear
        end

        it 'should allow to change vacation status to approve after clicking Yes button' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.yes_btn.click
          index_page.days.first.vacation_status.click
          index_page.days.first.wait_until_vacation_day_approved_visible
          expect(index_page.days.first).to have_vacation_day_approved
        end

        it 'should not allow to change vacation status to approve after clicking No button' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.yes_btn.click
          index_page.days.first.vacation_status.click
          expect(index_page).to_not have_confirm
          expect(index_page.days.first).to have_vacation_status
        end
      end

      context 'work day (with ranges)' do
        before do
          index_page.days.first.edit.click
          index_page.confirm.yes_btn.click
          index_page.days.first.save.click
          wait_for_ajax
        end

        it 'should show modal confirmation with edition_reject message' do
          index_page.days.first.vacation_clear.click
          expect(index_page.confirm.message.text).to eq(I18n.t(:edition_reject))
        end

        it 'should change day status to not_approved_vacation on Yes button click' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.yes_btn.click
          expect(index_page.days.first).to have_vacation_day_not_approved
        end

        it 'should not change day status on No button click' do
          index_page.days.first.vacation_clear.click
          index_page.confirm.no_btn.click
          expect(index_page.days.first).to_not have_vacation_day_not_approved
          expect(index_page.days.first).to have_vacation_clear
        end
      end

      context 'cleared day on not work day' do
        it 'should show modal confirmation with request_on_holiday message' do
          index_page.weekends.first.vacation_clear.click
          expect(index_page.confirm.message.text).to eq(I18n.t(:request_on_holliday))
        end

        it 'should change day status to approved_vacation on Yes button click' do
          index_page.weekends.first.vacation_clear.click
          index_page.confirm.yes_btn.click
          expect(index_page.weekends.first).to have_vacation_day_approved
        end

        it 'should not change day status on No button click' do
          index_page.weekends.first.vacation_clear.click
          index_page.confirm.no_btn.click
          expect(index_page.weekends.first).to_not have_vacation_day_approved
          expect(index_page.weekends.first).to have_vacation_clear
        end
      end
    end

    context 'Approve range of vacation' do
      let(:date) { (Date.today..Date.today + 4.days).detect { |date| !date.weekend? && !user.holiday?(date) } }

      before do
        populate_days date
        index_page.load(user_id: another_user.id)
        wait_for_ajax
      end

      it 'should allow to aprove all day in vacation range' do
        day_item(date).vacation_status.click
        index_page.modal_approve.approve.click
        index_page.wait_until_appoved_vacation_days_visible
        expect(index_page.appoved_vacation_days.count).to eq Day.count
      end

      context 'for two vacation ranges' do
        let(:future_date) {
          future_date = date + 14.days
          (future_date..future_date + 4.days).detect { |date| !date.weekend? && !user.holiday?(date) }
        }
        let(:day) { Day.for_date(date).where(user: another_user).first }
        let(:vacation_days) { day.vacation_range.select { |item| item.status == day.status } }

        before do
          populate_days future_date
          index_page.load(user_id: another_user.id)
          wait_for_ajax
        end

        it 'should allow to aprove all day in vacation range' do
          day_item(date).vacation_status.click
          index_page.modal_approve.approve.click
          index_page.wait_until_appoved_vacation_days_visible
          expect(index_page.appoved_vacation_days.count).to eq (Day.where(status: 'approved_vacation').count)
        end

        it 'should have text like approve dates from to' do
          day_item(date).vacation_status.click
          expect(index_page.modal_approve.all_days.text).to eq "#{l(vacation_days.first.date, format: :date_month_year)} to #{l(vacation_days.last.date, format: :date_month_year)}"
        end
      end
    end
  end

  context 'vacation hints' do
    before do
      login_as user.identity
      index_page.load(user_id: user.id)
      wait_for_ajax
    end

    it 'should show vacation hint' do
      index_page.days.first.vacation_clear.hover
      expect(index_page.hint).to be_visible
    end

    it 'should be with text "Create vacation"' do
      index_page.days.first.vacation_clear.hover
      expect(index_page.hint.text).to eq(I18n.t(:create_vacation))
    end

    it 'should be with text "Created by user dd month" for not approved vacation' do
      wait_for_ajax
      index_page.days.first.vacation_clear.click
      index_page.days.first.vacation_day_not_approved.hover
      expect(index_page.hint.text).to eq("Created by #{user.full_name} #{I18n.l(Date.today, format: :date_month)}")
    end

    it 'should be with text "Approved by user dd month" for approved vacation' do
      index_page.days.first.vacation_clear.click
      index_page.days.first.vacation_day_not_approved.click
      index_page.days.first.vacation_day_approved.hover
      expect(index_page.hint.text).to eq("Approved by #{user.full_name} #{I18n.l(Date.today, format: :date_month)}")
    end
  end
end

def day_item date
  index_page.days.detect { |item| item.date.text == I18n.l(date, format: :mon_day_year) }
end

def populate_days date
  10.times do |i|
    date_item = date + i.days
    Day.create date: date_item, user: another_user, status: :not_approved_vacation if !date_item.weekend? && !user.holiday?(date_item)
  end
end
