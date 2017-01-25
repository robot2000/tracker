describe Day, type: :model do
  before(:all) do
    Timecop.travel('2016/11/08')
  end

  after(:all) do
    Timecop.return
  end

  let(:user) { create(:identity).user }

  before do
    ['2016-11-07', '2016-11-10', '2016-11-11'].each do |date|
      create :day, date: date, user: user, status: 'not_approved_vacation'
      create :day, date: date.to_date + 1.week, user: user, status: 'not_approved_vacation'
      create :day, date: date.to_date + 2.week, user: user, status: 'not_approved_vacation'
      create :day, date: date.to_date + 4.week, user: user, status: 'not_approved_vacation'
    end
     create :day, date: '2016-11-08', user: user, status: 'not_approved_vacation'
     create :day, date: '2016-11-29', user: user, status: 'not_approved_vacation'
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-11-10')).to eq (['2016-11-10', '2016-11-11', '2016-11-14'])
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-11-18')).to eq (['2016-11-17', '2016-11-18', '2016-11-21'])
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-11-25')).to eq (['2016-11-24', '2016-11-25'])
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-11-24')).to eq (['2016-11-24', '2016-11-25'])
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-11-29')).to eq (['2016-11-29'])
  end

  it 'should select days in range with gap less then tree days' do
    expect(day_array('2016-12-05')).to eq (['2016-12-05'])
  end

  it 'should select only current day if day.date in the past' do
    expect(day_array('2016-11-07')).to eq (['2016-11-07'])
  end

  def day_array date
    user.days.for_date(date).first.vacation_range.pluck(:date).map { |i| i.strftime('%Y-%m-%d') }.sort
  end

end
