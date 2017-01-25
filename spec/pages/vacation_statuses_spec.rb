feature 'Vacation page', type: :feature, js: true do

  after(:all) do
    Timecop.return
  end

  let(:user) { create(:identity, :developer).user }
  let(:index_page) { TimeTable::IndexPage.new }

  context 'vacation statuses' do

    before(:all) do
      Timecop.travel('2016/11/08')
    end

    before do
      allow(PaperTrail).to receive(:whodunnit) { user.id.to_s }
      ['2016-11-07', '2016-11-10', '2016-11-11'].each do |date|
        create :day, date: date, user: user, status: 'not_approved_vacation'
        create :day, date: date.to_date + 1.week, user: user, status: 'not_approved_vacation'
        create :day, date: date.to_date + 2.week, user: user, status: 'not_approved_vacation'
        create :day, date: date.to_date + 4.week, user: user, status: 'not_approved_vacation'
      end
      create :day, date: '2016-11-08', user: user, status: 'approved_vacation'
      create :day, date: '2016-11-16', user: user, status: 'approved_vacation'
      create :day, date: '2016-11-29', user: user, status: 'approved_vacation'
    end

    before do
      login_as user.identity
      index_page.load(user_id: user.id)
      wait_for_ajax
    end

    it 'should change statuses for days in vacation range with several gaps' do
      expect(index_page.appoved_vacation_days.count).to eq 3
      expect(index_page.vacation_days.count).to eq 12
      dday_item('2016-11-10').vacation_status.click
      index_page.wait_until_modal_approve_visible
      index_page.modal_approve.approve.click
      index_page.wait_until_modal_approve_invisible
      expect(index_page.appoved_vacation_days.count).to eq 6
      expect(index_page.vacation_days.count).to eq 9
    end

    it 'should change statuses for days in vacation range with several gaps' do
      dday_item('2016-11-17').vacation_status.click
      index_page.wait_until_modal_approve_visible
      index_page.modal_approve.approve.click
      index_page.wait_until_modal_approve_invisible
      expect(index_page.appoved_vacation_days.count).to eq 6
      expect(index_page.vacation_days.count).to eq 9
    end

    it 'should change statuses for days in range with gap 2 days' do
      dday_item('2016-11-25').vacation_status.click
      index_page.wait_until_modal_approve_visible
      index_page.modal_approve.approve.click
      index_page.wait_until_modal_approve_invisible
      expect(index_page.appoved_vacation_days.count).to eq 5
      expect(index_page.vacation_days.count).to eq 10
    end

    it 'should change statuses for days in range with gap 2 days' do
      dday_item('2016-12-09').vacation_status.click
      index_page.wait_until_modal_approve_visible
      index_page.modal_approve.approve.click
      index_page.wait_until_modal_approve_invisible
      expect(index_page.appoved_vacation_days.count).to eq 5
      expect(index_page.vacation_days.count).to eq 10
    end

    it 'should change statuses for days in range with gap 2 days' do
      dday_item('2016-11-29').vacation_status.click
      wait_for_ajax
      expect(index_page.appoved_vacation_days.count).to eq 2
      expect(index_page.vacation_days.count).to eq 13
    end

    it 'should change statuses for days in range with gap 2 days' do
      dday_item('2016-11-16').vacation_status.click
      index_page.wait_until_modal_approve_visible
      index_page.modal_approve.approve.click
      index_page.wait_until_modal_approve_invisible
      expect(index_page.appoved_vacation_days.count).to eq 2
      expect(index_page.vacation_days.count).to eq 13
    end
  end

  context 'one vacation day' do

    before(:all) do
      Timecop.travel('2017/01/16')
    end

    before do
      login_as user.identity
      index_page.load(user_id: user.id)
      wait_for_ajax
    end

    it 'not have modal_window approve with only current day' do
      dday_item('2017-01-16').vacation_clear.click
      wait_for_ajax
      dday_item('2017-01-20').vacation_clear.click
      wait_for_ajax
      dday_item('2017-01-20').vacation_status.click
      wait_for_ajax
      expect(index_page).to_not have_modal_approve
      expect(index_page.appoved_vacation_days.count).to eq 1
      expect(index_page.vacation_days.count).to eq 1
    end
  end
end

def dday_item date
  index_page.days.detect { |item| item.date.text == l(date.to_date, format: :mon_day_year) }
end
