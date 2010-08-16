module SimpleCrowd
  class Group < CrowdEntity
    property :id
    property :name
    property :active
    property :description
    property :directory_id

    property :members
    property :attributes
  end
end