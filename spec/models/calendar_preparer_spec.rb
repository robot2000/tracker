describe CalendarPreparer, type: :model do
  let(:user1) { create :user }
  let(:user2) { create :user }
  let(:user3) { create :user }

  let!(:vacation1) { create :day, user: user1, date: Date.today - 1.day, status: 'approved_vacation' }
  let!(:vacation2) { create :day, user: user2, date: Date.today - 1.day, status: 'approved_vacation';
                     create :day, user: user2, date: Date.today, status: 'approved_vacation' }
  let!(:vacation3) { create :day, user: user3, date: Date.today, status: 'approved_vacation' }

  let(:vacations)  { Day.joins('LEFT OUTER JOIN work_times AS wt ON days.id = wt.day_id').where('wt.id IS NULL').group_by(&:date) }
  let(:preparer)   { CalendarPreparer.new((Date.today - 1.weeks).beginning_of_week...Date.today.beginning_of_week + 2.weeks, User.all) }

  context '' do
    before(:all) do
      Timecop.travel('2016/11/23')
    end

    before do
      preparer.generate_dates
    end

    it 'may be initialized' do
      expect(preparer.vacation_dates.keys.sort).to eq vacations.keys.sort
      expect(preparer.vacation_dates.values.flatten.sort).to eq vacations.values.flatten.sort
    end

    it 'collect user ids' do
      expect(preparer.user_ids([Day.first, nil, Day.last])).to match_array [user1.id, nil, user3.id]
    end

    context 'with duplicates' do
      it 'can calc duplicates' do
        expect(preparer.duplicates.map(&:user_id)).to match_array [user2.id]
      end

      context 'populate new day' do
        before do
          preparer.build_new_day
        end

        it 'build new day' do
          expect(preparer.new_day_state).to match_array [nil, vacation2.user.days.last]
        end

        it 'fill empty space' do
          preparer.fill_with_others
          expect(preparer.new_day_state).to match_array [vacation3.user.days.last, vacation2.user.days.last]
        end
      end
    end

    after(:all) do
      Timecop.return
    end
  end

  context 'right sorting' do
    before(:all) do
      Timecop.travel('2016/11/21')
    end

    let!(:vacation1) { create :day, user: user1, date: '2016/11/18', status: 'approved_vacation' }
    let!(:vacation2) { create :day, user: user1, date: '2016/11/17', status: 'approved_vacation' }
    let!(:vacation3) { create :day, user: user2, date: '2016/11/18', status: 'approved_vacation' }
    let!(:vacation4) { create :day, user: user3, date: '2016/11/18', status: 'approved_vacation' }
    let!(:vacation5) { create :day, user: user1, date: '2016/11/21', status: 'approved_vacation' }
    let!(:vacation6) { create :day, user: user2, date: '2016/11/21', status: 'approved_vacation' }
    let!(:vacation7) { create :day, user: user3, date: '2016/11/21', status: 'approved_vacation' }
    let!(:calendar) { CalendarPreparer.new((Date.today - 1.weeks).beginning_of_week...Date.today.beginning_of_week + 2.weeks, User.all) }

    before do
      calendar.generate_dates
    end

    it 'should be the order of the vacations on Monday equal to the order on Friday' do
      expect(calendar.new_day_state.map(&:user_id)).to match_array calendar.previous_step.map(&:user_id)
    end

    it 'should be the order of the vacations on Monday equal to the order on Saturday' do
      vacation1.update_attributes(date: '2016/11/19')
      vacation2.update_attributes(date: '2016/11/18')
      vacation3.update_attributes(date: '2016/11/19')
      vacation4.update_attributes(date: '2016/11/19')
      expect(calendar.new_day_state.map(&:user_id)).to match_array calendar.previous_step.map(&:user_id)
    end

    it 'should return the nearest workday before weekend or holiday' do
      expect(calendar.check('2016/11/20'.to_date)).to eq ('2016/11/18'.to_date)
      expect(calendar.check('2016/11/19'.to_date)).to eq ('2016/11/18'.to_date)
    end

    after(:all) do
      Timecop.return
    end
  end
end
