class GeneralPage < SitePrism::Page
  set_url '/'

  element :logo, '.logo.pull-left'
  element :user_email, '.nav.navbar-nav.pull-right'
  element :success, '.alert-success'
  element :error, '.alert.fade.in.alert-danger'
  element :active_header_link, '.header-menu__link.active'
  element :link_user_weeks, 'a', text: 'Users weeks'
end
