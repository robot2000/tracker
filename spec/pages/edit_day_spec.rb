shared_examples 'for clear' do
  it "Clear should remove ranges and don't set approve vacation" do
    wait_for_ajax
    day_item = detect_day_item index_page, date_id
    day_item.edit.click
    day_item.save.click
    day_item = detect_day_item index_page, date_id
    day_item.edit.click
    day_item.clear.click
    day_item = detect_day_item index_page, date_id
    if date_id.to_date.weekend? || identity.user.holiday?(date_id)
      expect(day_item).to_not have_default_ranges # on weekends default state is no ranges
    else
      wait_for_ajax
      expect(day_item.default_ranges.count).to eq 2 # on other days default state is 2 default ranges
    end
    expect(day_item).to_not have_css('.dashboard-item_vacation')
    expect(day_item).to_not have_css('.dashboard-item_approved')
  end
end

feature 'Day edition', type: :feature, js: true do
  let(:identity) { create :identity, :developer }
  let(:today) { Date.today }
  let(:beginning_of_week) { today.beginning_of_week }
  let(:date) { I18n.l today }
  let(:index_page) { TimeTable::IndexPage.new }
  let(:first_input) { index_page.days.first.ranges_to_edit.first }
  let(:second_input) { index_page.days.first.ranges_to_edit.last }

  before do
    login_as identity
    index_page.load(user_id: identity.user.id)
    wait_for_ajax
  end

  it 'have user name on page' do
    expect(index_page).to have_content(identity.user.full_name)
  end

  context 'edit day ranges' do
    before do
      wait_for_ajax
      index_page.days.first.edit.click
    end

    it 'have form rows for work_times' do
      expect(index_page.days.first.ranges_to_edit.count).to eq 2
    end

    it 'should allow to edit day work_times' do
      expect(index_page.days.first.ranges_to_edit.count).to eq 2
    end

    it 'should allow to edit the only one day' do
      expect(index_page.days.first.ranges_to_edit.count).to eq 2
      index_page.days.second.edit.click
      expect(index_page.days.first.default_ranges.count).to eq 2 # no ranges_to_edit, only default_ranges
      expect(index_page.days.second.ranges_to_edit.count).to eq 2
    end

    it 'Cancel button should render show day partial' do
      expect(index_page.days.first.ranges_to_edit.count).to eq 2
      index_page.days.first.cancel.click
      expect(index_page.days.first.default_ranges.count).to eq 2 # no ranges_to_edit, only default_ranges
    end

    context 'event by pressing keys' do
      before do
        wait_for_ajax
        second_input.send_keys(:enter)
      end

      it 'should add new empty range by pressing enter key' do
        expect(index_page.days.first.ranges_to_edit.count).to eq 3
      end

      it 'should delete current empty range by pressing backspace key' do
        expect(index_page.days.first.ranges_to_edit.count).to eq 3
        second_input.send_keys(:backspace)
        expect(index_page.days.first.ranges_to_edit.count).to eq 2
      end
    end

    context 'inputting data' do
      it 'should highlight incorrect data with red color' do
        index_page.wait_for_days
        second_input.send_keys(:enter)
        second_input.set('some data')
        expect(index_page.days.first.ranges_with_incorrect_data.count).to eq 1
      end
    end

    context 'checking update' do
      it 'should have Save button' do
        expect(index_page.days.first.save).to be_visible
      end

      it 'should have Cancel button' do
        expect(index_page.days.first.cancel).to be_visible
      end

      it 'should not have Clear button for first edition' do
        index_page.wait_for_days
        expect(index_page.days.first).to_not have_clear
      end

      it 'should have Clear button after edition' do
        index_page.days.first.save.click
        index_page.days.first.edit.click
        expect(index_page.days.first).to have_clear
      end

      it 'should not have Clear button after click Clear' do
        wait_for_ajax
        index_page.days.first.save.click
        index_page.days.first.edit.click
        index_page.days.first.clear.click
        expect(index_page.days.first).to_not have_clear
      end

      it 'should highlight incorrect data with crossed ranges' do
        first_input.set('08:00 - 12:00')
        second_input.set('11:00 - 18:00')
        index_page.days.first.save.click
        expect(index_page.days.first.ranges_with_incorrect_data.count).to eq 2
      end

      it 'should highlight incorrect data with start before stop range' do
        first_input.set('08:00 - 12:00')
        second_input.set('18:00 - 13:00')
        expect(index_page.days.first.ranges_with_incorrect_data.count).to eq 1
      end

      describe 'total time' do
        it 'should be visible after Save click' do
          index_page.days.first.save.click
          expect(index_page.days.first.total_time.text).to have_content('8:00')
        end

        it 'should be visible after change ranges and Save click' do
          first_input.set('')
          index_page.days.first.save.click
          expect(index_page.days.first.total_time.text).to have_content('5:00')
        end

        it 'should not be visible after Clear click' do
          wait_for_ajax
          index_page.days.first.save.click
          index_page.days.first.edit.click
          index_page.days.first.clear.click
          expect(index_page.days.first).to_not have_total_time
        end

        it 'should be visible with 0 hours for vacation' do
          wait_for_ajax
          first_input.set('')
          second_input.set('')
          index_page.days.first.save.click
          expect(index_page.days.first.total_time.text).to have_content('0:00')
        end

        context 'vacation' do
          it 'deleting all ranges should give not approve vacation' do
            first_input.set('')
            second_input.set('')
            index_page.days.first.save.click
            expect(index_page.days.first).to have_css('.dashboard-item_vacation')
          end
        end
      end
    end

    context 'auto approving vacation' do
      let(:first_range) { index_page.weekends.first.ranges_to_edit.first }
      let(:second_range) { index_page.weekends.first.ranges_to_edit.last }

      it 'should auto approve on weekend if label clicked' do
        index_page.weekends.first.vacation_status.click
        expect(index_page.confirm).to be_visible
        index_page.confirm.yes_btn.click
        expect(index_page.weekends.first).to have_vacation_day_approved
      end

      it 'should not auto approve on weekend if ranges cleared manually' do
        index_page.weekends.first.edit.click
        first_range.set('')
        second_range.set('')
        index_page.weekends.first.save.click
        expect(index_page.weekends.first).to have_vacation_clear
      end
    end

    context 'edition existing work_times' do
      before do
        wait_for_ajax
        index_page.days.first.save.click
        index_page.days.first.edit.click
      end

      it 'should have Clear button' do
        expect(index_page.days.first.clear).to be_visible
      end

      it 'Clear should remove ranges' do
        index_page.days.first.clear.click
        expect(index_page.days.first.default_ranges.count).to eq 2
      end

      it 'editing ranges with not ordered ranges should save and render with ordered ranges' do
        wait_for_ajax
        first_input.set('13:00 - 20:00')
        second_input.set('08:00 - 12:00')
        index_page.days.first.save.click
        expect(index_page.days.first.ranges.first.text).to eq('8:00 - 12:00')
      end

      it 'edition ranges with shot time format in stop' do
        first_input.set('08:00 - 9:30')
        index_page.days.first.save.click
        expect(index_page.days.first.ranges.first.text).to eq('8:00 - 9:30')
      end

      it 'edition ranges with shot time format in start' do
        wait_for_ajax
        first_input.set('9:00 - 12:00')
        index_page.days.first.save.click
        expect(index_page.days.first.ranges.first.text).to eq('9:00 - 12:00')
      end

      it 'edition ranges with shot time format in start and stop' do
        first_input.set('8:30 - 9:20')
        index_page.days.first.save.click
        index_page.days.first.wait_until_ranges_visible
        expect(index_page.days.first.ranges.first.text).to eq('8:30 - 9:20')
      end
    end
  end

  describe 'change vacation' do
    it 'should not show the link if approved vacation nil' do
      expect(index_page.days.first).to_not have_content('00:00')
    end

    it 'should auto approve vacation on the date: date now + 2 mounth' do
      Timecop.travel('2016/11/12')
      current_monday_plus_2_month = index_page.days.detect { |day_item| day_item.date.text.to_date == '2017-01-12'.to_date }
      current_monday_plus_2_month.vacation_status.click
      expect(current_monday_plus_2_month).to have_vacation_day_approved
      Timecop.return
    end
  end

  def current_monday_plus_2_month
    wait_for_ajax
    index_page.days.detect do |day_item|
      day_item.date.text.to_date > (beginning_of_week + 10.weeks) &&
                                   !day_item.date.text.to_date.weekend? &&
                                   !identity.user.holiday?(day_item.date.text.to_date)
    end
  end

  context 'can make vacation request' do
    before do
      index_page.days.first.vacation_clear.click
    end

    it 'can make vacation day' do
      expect(index_page.days.first.total_time.text).to have_content('0:00')
      expect(index_page.days.first).to have_vacation_status
    end

    it 'can make approved vacation day' do
      index_page.days.first.vacation_status.click
      expect(index_page.days.first.total_time.text).to have_content('0:00')
      expect(index_page).to_not have_modal_approve
    end

    it 'can turn day to default' do
      expect(index_page.days.first).to have_vacation_status
      index_page.days.first.edit.click
      index_page.days.first.clear.click
      expect(index_page.days.first).to_not have_total_time
      expect(index_page.days.first).to have_vacation_clear
    end
  end

  context 'edition day in 2 month after today' do
    let(:today_plus_2_month) { I18n.l(today + 2.month) }
    let(:today_plus_2_month_minus_1_day) { I18n.l(today + 2.month - 1.day) }
    let(:today_plus_2_month_plus_1_day) { I18n.l(today + 2.month + 1.day) }

    describe 'date = current date + 2 month' do
      it_behaves_like('for clear') { let(:date_id) { today_plus_2_month } }
    end

    describe 'date = current date + 2 month - 1 day' do
      it_behaves_like('for clear') { let(:date_id) { today_plus_2_month_minus_1_day } }
    end

    describe 'date = current date + 2 month + 1 day' do
      it_behaves_like('for clear') { let(:date_id) { today_plus_2_month_plus_1_day } }
    end
  end

  def detect_day_item page, date_id
    wait_for_ajax
    page.days.detect { |item| item.date.text.to_date == date_id.to_date }
  end
end
