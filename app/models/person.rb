# A person is the profile of an user holding all relationships with the rest of the system
class Person < Profile
  acts_as_accessor

#  has_many :friendships
#  has_many :friends, :class_name => 'Person', :through => :friendships
#  has_many :person_friendships
#  has_many :people, :through => :person_friendships, :foreign_key => 'friend_id'
  
  has_one :person_info
#  has_many :role_assignments, :as => :accessor, :class_name => 'RoleAssignment'

#  def has_permission?(perm, res=nil)
#    return true if res == self && PERMISSIONS[:profile].keys.include?(perm) 
#    role_assignments.any? {|ra| ra.has_permission?(perm, res)}
#  end

  def self.conditions_for_profiles(conditions, person)
    new_conditions = sanitize_sql(['role_assignments.accessor_id = ?', person])
    new_conditions << ' AND ' +  sanitize_sql(conditions) unless conditions.blank?
    new_conditions
  end

  def memberships(conditions = {})
    Profile.find(
      :all, 
      :conditions => self.class.conditions_for_profiles(conditions, self), 
      :joins => "LEFT JOIN role_assignments ON profiles.id = role_assignments.resource_id AND role_assignments.resource_type = \'#{Profile.base_class.name}\'",
      :select => 'profiles.*').uniq
  end
  
  def info
    person_info
  end

  validates_presence_of :user_id

  def initialize(*args)
    super(*args)
    self.person_info ||= PersonInfo.new
    self.person_info.person = self
  end

  def email
    self.user.nil? ? nil : self.user.email
  end

  def is_admin?
    role_assignments.map{|ra|ra.role.permissions}.any? do |ps|
      ps.any? do |p|
        ActiveRecord::Base::PERMISSIONS[:environment].keys.include?(p)
      end
    end
  end
end
