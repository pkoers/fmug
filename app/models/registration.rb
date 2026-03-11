class Registration < ApplicationRecord
  belongs_to :user
  belongs_to :conference

  validates :attending_physically, inclusion: { in: [ true, false ] }
  validates :user_id, uniqueness: { scope: :conference_id }
  validate :agenda_selection_required
  validate :dietary_requirements_text_needed

  before_validation :normalize_optional_text_fields

  private

  def agenda_selection_required
    return if agenda_present || agenda_question || agenda_something_else || agenda_nothing_to_present

    errors.add(:base, "Select at least one agenda option")
  end

  def dietary_requirements_text_needed
    return unless has_dietary_requirements
    return if dietary_requirements_text.present?

    errors.add(:dietary_requirements_text, "must be provided when dietary requirements are selected")
  end

  def normalize_optional_text_fields
    self.agenda_something_else_text = agenda_something_else_text.to_s.strip.presence
    self.chair_note = chair_note.to_s.strip.presence

    cleaned_dietary_text = dietary_requirements_text.to_s.strip
    self.dietary_requirements_text = if has_dietary_requirements && cleaned_dietary_text != "Please specify"
      cleaned_dietary_text.presence
    end
  end
end
