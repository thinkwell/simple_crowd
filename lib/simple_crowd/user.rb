module SimpleCrowd
  class User < CrowdEntity
    # Immutable properties
    property :id, :immutable => true
    property :username, :immutable => true, :map_soap => :name
    property :directory_id, :immutable => true, :search_restriction => 'principal.directory.id'

    property :active, :default => true, :search_restriction => 'principal.active'
    property :description

    # Assumed available attributes (with soap aliases)
    attribute :first_name, :map_soap => :givenName
    attribute :last_name, :map_soap => :sn
    attribute :display_name, :map_soap => :displayName, :search_restriction => 'principal.fullname'
    attribute :email, :map_soap => :mail, :search_restriction => 'principal.email'

    def errors
      errors = super
      errors[:username] = "cannot be blank" if username.to_s == ""
      errors
    end
  end
end
