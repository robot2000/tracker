describe 'Day', type: :feature, js: true do
  let(:identity) { create :identity, :developer }
  let(:user) { create :user }
  let(:index_page) { TimeTable::IndexPage.new }

  context 'frozen time' do
    before(:all) do
      Timecop.travel('2016/11/07')
    end

    before do
      login_as identity
      allow(PaperTrail).to receive(:whodunnit) { identity.user.id.to_s }
    end

    let!(:vacation_day1) { create :day, date: '2016-11-07', user: identity.user, status: :not_approved_vacation }
    let!(:vacation_day2) { create :day, date: '2016-11-08', user: identity.user, status: :not_approved_vacation }
    let!(:vacation_day3) { create :day, date: '2016-11-07', user: user, status: :not_approved_vacation }

    context 'without comment' do
      before do
        index_page.load(user_id: identity.user.id)
        wait_for_ajax
      end

      it 'should show pencil for vacation create' do
        expect(index_page.days.first).to have_pencil
      end

      it 'should show modal comment on pencil click' do
        index_page.days.first.pencil.click
        expect(index_page.modal_comment).to have_comment_textarea
        expect(index_page.modal_comment).to have_all_days_radio_button
        expect(index_page.modal_comment).to have_current_day_radio_button
        expect(index_page.modal_comment).to have_cancel
        expect(index_page.modal_comment).to have_save
      end

      it 'should have comment_icon after save comment for current day' do
        index_page.days.first.pencil.click
        index_page.modal_comment.current_day_radio_button.click
        index_page.modal_comment.comment_textarea.set 'Comment'
        index_page.modal_comment.save.click
        expect(index_page.days.first).to have_comment_icon
      end

      it 'should have comment_icon after save comment for all days' do
        index_page.days.first.pencil.click
        index_page.modal_comment.all_days_radio_button.click
        index_page.modal_comment.comment_textarea.set 'Comment'
        index_page.modal_comment.save.click
        expect(index_page.days.first).to have_comment_icon
        expect(index_page.days.second).to have_comment_icon
      end

      it 'should return day after cancel click' do
        index_page.days.first.pencil.click
        index_page.modal_comment.cancel.click
        expect(index_page.days.first).to have_pencil
      end

      it 'should set the same comment for all vacation days by choosing all days radio button' do
        index_page.days.first.pencil.click
        index_page.modal_comment.comment_textarea.set 'Comment'
        index_page.modal_comment.save.click
        expect(index_page.days.second).to have_comment_icon
        index_page.days.second.comment_icon.click
        expect(index_page.modal_comment.comment_textarea.text).to eq 'Comment'
      end

      it 'should change icon from comment_icon to pencil after remove comment text' do
        index_page.days.first.pencil.click
        index_page.modal_comment.comment_textarea.set 'Comment'
        index_page.modal_comment.save.click
        index_page.days.first.comment_icon.click
        index_page.modal_comment.comment_textarea.set ''
        index_page.modal_comment.save.click
        expect(index_page.days.first).to have_pencil
        expect(index_page.days.second).to have_pencil
      end
    end

    context 'without comment' do
      before do
        index_page.load(user_id: user.id)
        wait_for_ajax
      end

      it 'should show modal comment on pencil click for another user' do
        index_page.days.first.pencil.click
        expect(index_page.modal_comment).to have_comment_textarea
        expect(index_page.modal_comment).to have_cancel
        expect(index_page.modal_comment).to have_save
      end
    end

    context 'hint' do
      before do
        vacation_day1.update_attributes comment: 'comment'
        allow(PaperTrail).to receive(:whodunnit) { identity.user.id.to_s }
        index_page.load(user_id: identity.user.id)
        wait_for_ajax
      end

      it 'should show comment hint' do
        index_page.days.first.comment_icon.hover
        expect(index_page.hint).to be_visible
      end

      it 'should show comment with text: who and what wrote' do
        index_page.days.first.comment_icon.hover
        expect(index_page.hint.text).to eq("#{identity.email} wrote comment")
      end

      it 'should not reset comment when set ranges' do
        index_page.days.first.edit.click
        index_page.days.first.save.click
        expect(index_page.days.first.comment_icon).to be_visible
      end
    end

    after(:all) do
      Timecop.return
    end
  end

  context 'in the past' do
    before(:all) do
      Timecop.travel('2016/11/09')
    end

    before do
      login_as identity
      allow(PaperTrail).to receive(:whodunnit) { identity.user.id.to_s }
    end

    let!(:not_approved_day) { create :day, date: '2016-11-07', user: identity.user, status: :not_approved_vacation }
    let!(:approved_day) { create :day, date: '2016-11-08', user: identity.user, status: :approved_vacation }

    before do
      index_page.load(user_id: identity.user.id)
      wait_for_ajax
    end

    it 'should have no radio buttons' do
      index_page.days.first.pencil.click
      expect(index_page.modal_comment).to_not have_all_days_radio_button
      expect(index_page.modal_comment).to_not have_current_day_radio_button
      expect(index_page.modal_comment).to have_label_without_radio_button
    end

    it 'should save comment' do
      index_page.days.first.pencil.click
      index_page.modal_comment.comment_textarea.set 'Comment'
      index_page.modal_comment.save.click
      index_page.days.first.comment_icon.click
      expect(index_page.modal_comment.comment_textarea.text).to eq 'Comment'
    end

    it 'should save comment only for choosen day' do
      index_page.days.first.pencil.click
      index_page.modal_comment.comment_textarea.set 'Comment'
      index_page.modal_comment.save.click
      expect(index_page.days.second).to have_pencil
    end

    after(:all) do
      Timecop.return
    end
  end
end
