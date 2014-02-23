class Person < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :email, :phone
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_format_of :twitter, :with => /\A^@\w+\z/i, :allow_nil => true, :allow_blank => true, :message => 'needs to begin with @ and be one word'
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with PersonValidator, :on => :create

  belongs_to :registration

  def self.registered_for_race(race_id)
    race = Race.find race_id
    race.finalized_registrations.inject([]) do |total, reg|
      total.concat reg.people.reject{ |person| person.email.downcase =~ /unknown/}
    end
  end
end
