module TimeTable
  class ModalApprove < ::SitePrism::Section
    element :current_day, "label[for='vacation_for_one_day']"
    element :all_days, "label[for='vacation_for_all_days']"
    element :approve, '.modal-form__btn'
    element :unapprove, '.modal-form__btn'
    element :cancel, '.modal__cancel'
  end
end
