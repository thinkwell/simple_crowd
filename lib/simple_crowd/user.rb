module SimpleCrowd
  class User < CrowdEntity

    # Immutable properties
    property :id, :immutable => true
    property :username, :immutable => true, :map_soap => :name
    property :description, :immutable => true
    property :active, :immutable => true, :default => true
    property :directory_id, :immutable => true

    # Assumed available attributes (with soap aliases)
    property :first_name, :attribute => true, :map_soap => :givenName
    property :last_name, :attribute => true, :map_soap => :sn
    property :display_name, :attribute => true, :map_soap => :displayName
    property :email, :attribute => true, :map_soap => :mail
  end
end