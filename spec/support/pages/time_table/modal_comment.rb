module TimeTable
  class ModalComment < ::SitePrism::Section
    element :all_days_radio_button, "label[for='comment_for_all_days']"
    element :current_day_radio_button, "label[for='comment_for_one_day']"
    element :label_without_radio_button, '.modal-text'
    element :comment_textarea, "textarea[name='day[comment]']"
    element :save, "input[type='submit']"
    element :cancel, '.btn.noBtn'
  end
end
