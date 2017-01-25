module TimeTable
  class Confirm < ::SitePrism::Section
    element :message, '.modal__body'
    element :yes_btn, '.yesBtn'
    element :no_btn, '.noBtn'
  end
end
