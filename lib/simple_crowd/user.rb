module SimpleCrowd
  class User < ExtendedDash

    # Immutable properties
    property :id
    property :username, :map_soap => :name
    property :description
    property :active
    property :directory_id

    # Assumed available attributes (with soap aliases)
    property :first_name, :map_soap => :givenName
    property :last_name, :map_soap => :sn
    property :display_name, :map_soap => :displayName
    property :email, :map_soap => :mail

    property :attributes, :default => {}
  end
end