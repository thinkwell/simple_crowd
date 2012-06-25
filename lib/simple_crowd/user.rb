module SimpleCrowd
  class User < CrowdEntity
    # Immutable properties
    property :id, :immutable => true
    property :username, :immutable => true, :map_soap => :name
    property :directory_id, :immutable => true

    property :active, :default => true
    property :description

    # Assumed available attributes (with soap aliases)
    attribute :first_name, :map_soap => :givenName
    attribute :last_name, :map_soap => :sn
    attribute :display_name, :map_soap => :displayName
    attribute :email, :map_soap => :mail
  end
end
