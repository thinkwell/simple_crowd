module SimpleCrowd
  class Group < CrowdEntity
    property :id, :immutable => true
    property :name, :immutable => true
    property :directory_id, :immutable => true

    property :active, :default => true
    property :description

    property :members
  end
end
