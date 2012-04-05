module SimpleCrowd
  class Group < CrowdEntity
    property :id
    property :name
    property :active, :default => true
    property :description
    property :directory_id

    property :members
  end
end