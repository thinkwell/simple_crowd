FactoryGirl.define do
  factory :user, :class => SimpleCrowd::User do
    first_name 'Test'
    last_name  'User'
    display_name {|a| "#{a.first_name} #{a.last_name}"}
    email {|a| "#{a.first_name}.#{a.last_name}@example.com".downcase }
    sequence(:username) {|n| "test#{n}" }
    # Clear dirty properties
    after_build { |user| user.dirty_properties.clear }
  end
end
