# A Profile is the representation and web-presence of an individual or an
# organization. Every Profile is attached to its VirtualCommunity of origin,
# which by default is the one returned by VirtualCommunity:default.
class Profile < ActiveRecord::Base

  act_as_flexible_template

  # Valid identifiers must match this format.
  IDENTIFIER_FORMAT = /^[a-z][a-z0-9_]*[a-z0-9]$/

  # These names cannot be used as identifiers for Profiles
  RESERVED_IDENTIFIERS = %w[
  admin
  customize
  cms
  system
  community
  ]

  has_many :affiliations
  has_many :people, :through => :affiliations
  has_many :domains, :as => :owner
  belongs_to :virtual_community
  belongs_to :profile_owner, :polymorphic => true


  # Sets the identifier for this profile. Raises an exception when called on a
  # existing profile (since profiles cannot be renamed)
  def identifier=(value)
    unless self.new_record?
      raise ArgumentError.new(_('An existing profile cannot be renamed.'))
    end
    self[:identifier] = value
  end

  validates_presence_of :identifier
  validates_format_of :identifier, :with => IDENTIFIER_FORMAT
  validates_exclusion_of :identifier, :in => RESERVED_IDENTIFIERS

  # A profile_owner cannot have more than one profile, but many profiles can exist
  # without being associated to a particular user.
  validates_uniqueness_of :user_id, :if => (lambda do |profile|
    ! profile.user_id.nil?
  end)

  # creates a new Profile. By default, it is attached to the default
  # VirtualCommunity (see VirtualCommunity#default), unless you tell it
  # otherwise
  def initialize(*args)
    super(*args)
    self.virtual_community ||= VirtualCommunity.default
  end

end
