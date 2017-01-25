feature 'Vacation page', type: :feature, js: true do
  let(:user1) { create(:identity, :dnepr, :developer, email: 'am@anadeainc.com').user }
  let(:user2) { create(:identity, :dnepr, :pm, email: 'ao@anadeainc.com').user }
  let(:user3) { create(:identity, :dnepr, :developer, email: 'eum@anadeainc.com').user }
  let(:date) { not_holiday Date.today }
  let(:date_plus_2_month) { not_holiday(date + 2.month) }
  let(:show_page) { Vacations::ShowPage.new }

  before do
    allow(PaperTrail).to receive(:whodunnit) { user1.id.to_s }
    login_as user1.identity
  end

  after(:all) do
    Timecop.return
  end

  context 'filtering' do
    before(:all) do
      Timecop.travel('2016/11/18')
    end

    let!(:vacation1) { create :day, user: user1, date: date, status: 'not_approved_vacation' }
    let!(:vacation2) { create :day, user: user1, date: date_plus_2_month, status: 'approved_vacation' }

    before do
      show_page.load
    end

    it 'should return vacations by office' do
      show_page.office_dnepr.click
      show_page.wait_for_datepicker
      show_page.datepicker.set(Date.today)
      show_page.wait_until_loadSpinner_visible
      show_page.wait_until_loadSpinner_invisible
      show_page.calendar_day.first.click
      show_page.office_dnepr.click
      show_page.wait_for_pending_vacations
      expect(show_page).to have_pending_vacations
      show_page.wait_for_approve_vacations
      expect(show_page).to have_approve_vacations
      expect(show_page).to have_datepicker
    end

    it 'should display dnepr office' do
      expect(show_page).to have_office_dnepr
    end

    after(:all) do
      Timecop.return
    end
  end

  context 'checking sort' do
    before(:all) do
      Timecop.travel('2016/11/18')
    end

    let!(:vacation1) { create :day, user: user1, date: Date.today,          status: 'not_approved_vacation' }
    let!(:vacation2) { create :day, user: user2, date: Date.today,          status: 'not_approved_vacation' }
    let!(:vacation3) { create :day, user: user3, date: Date.today,          status: 'not_approved_vacation' }
    let!(:vacation4) { create :day, user: user1, date: Date.today - 1.days, status: 'not_approved_vacation' }
    let!(:vacation5) { create :day, user: user1, date: Date.today + 3.days, status: 'not_approved_vacation' }
    let!(:vacation6) { create :day, user: user2, date: Date.today + 3.days, status: 'not_approved_vacation' }
    let!(:vacation7) { create :day, user: user3, date: Date.today + 3.days, status: 'not_approved_vacation' }

    before do
      show_page.load(id: Date.today.year.to_s)
    end

    it 'the order of the vacations on Monday must be equal to the order on Friday with not_approved statuses' do
      show_page.wait_for_dates
      expect(show_page.dates[4].users_not_approved[0]['data-user-id']).to eq show_page.dates[7].users_not_approved[0]['data-user-id']
      expect(show_page.dates[4].users_not_approved[1]['data-user-id']).to eq show_page.dates[7].users_not_approved[1]['data-user-id']
      expect(show_page.dates[4].users_not_approved[2]['data-user-id']).to eq show_page.dates[7].users_not_approved[2]['data-user-id']
    end

    it 'the order of the vacations on Monday must be equal to the order on Friday with approved statuses' do
      vacation1.update_attributes(status: 'approved_vacation')
      vacation2.update_attributes(status: 'approved_vacation')
      vacation3.update_attributes(status: 'approved_vacation')
      vacation4.update_attributes(status: 'approved_vacation')
      vacation5.update_attributes(status: 'approved_vacation')
      vacation6.update_attributes(status: 'approved_vacation')
      vacation7.update_attributes(status: 'approved_vacation')
      show_page.load(id: Date.today.year.to_s)

      show_page.wait_for_dates
      expect(show_page.dates[4].users_approved[0]['data-user-id']).to eq show_page.dates[7].users_approved[0]['data-user-id']
      expect(show_page.dates[4].users_approved[1]['data-user-id']).to eq show_page.dates[7].users_approved[1]['data-user-id']
      expect(show_page.dates[4].users_approved[2]['data-user-id']).to eq show_page.dates[7].users_approved[2]['data-user-id']
    end

    it 'the order of the vacations on Monday must be equal to the order on Friday with others statuses' do
      wait_for_ajax
      vacation1.update_attributes(status: 'approved_vacation')
      vacation2.update_attributes(status: 'approved_vacation')
      vacation3.update_attributes(status: 'approved_vacation')
      vacation4.update_attributes(status: 'approved_vacation')
      show_page.load(id: Date.today.year.to_s)

      show_page.wait_for_dates
      expect(show_page.dates[4].users_approved[0]['data-user-id']).to eq show_page.dates[7].users_not_approved[0]['data-user-id']
      expect(show_page.dates[4].users_approved[1]['data-user-id']).to eq show_page.dates[7].users_not_approved[1]['data-user-id']
      expect(show_page.dates[4].users_approved[2]['data-user-id']).to eq show_page.dates[7].users_not_approved[2]['data-user-id']
    end
  end

  private
  def not_holiday date
    (date...date + 7.days).detect { |d| !d.weekend? && !Location.holiday?(d, :ukraine) }
  end
end
