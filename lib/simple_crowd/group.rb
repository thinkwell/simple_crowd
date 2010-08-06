module SimpleCrowd
  class Group < ExtendedDash
    property :id
    property :name
    property :active
    property :description
    property :directory_id

    property :members
    property :attributes
  end
end