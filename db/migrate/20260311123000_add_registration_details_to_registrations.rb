class AddRegistrationDetailsToRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :registrations, :agenda_present, :boolean, null: false, default: false
    add_column :registrations, :agenda_question, :boolean, null: false, default: false
    add_column :registrations, :agenda_something_else, :boolean, null: false, default: false
    add_column :registrations, :agenda_something_else_text, :text
    add_column :registrations, :agenda_nothing_to_present, :boolean, null: false, default: false
    add_column :registrations, :has_dietary_requirements, :boolean, null: false, default: false
    add_column :registrations, :dietary_requirements_text, :text
    add_column :registrations, :chair_note, :text
  end
end
