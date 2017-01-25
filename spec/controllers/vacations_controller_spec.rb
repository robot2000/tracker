describe VacationsController, type: :controller do

    context 'user is not loged in' do
      it 'should redirect to login path' do
        get :index
        expect(response).to have_http_status(302)
        expect(response).to redirect_to identity_google_oauth2_omniauth_authorize_path
      end
    end
end
