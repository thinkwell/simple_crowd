Factory.define :user, :class => SimpleCrowd::User do |u|
  u.first_name 'Test'
  u.last_name  'User'
  u.display_name {|a| "#{a.first_name} #{a.last_name}"}
  u.email {|a| "#{a.first_name}.#{a.last_name}@example.com".downcase }
  u.sequence(:username) {|n| "test#{n}" }
  # Clear dirty properties
  u.after_build { |user| user.dirty_properties.clear }
end