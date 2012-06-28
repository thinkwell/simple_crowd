# Client with basic functions mocked out to stop calls from going to the server during tests
module SimpleCrowd
  class MockClient
    class << self
      attr_accessor :users, :tokens, :groups

      def reset
        @users, @tokens, @groups = [], [], []
      end
    end

    attr_accessor :app_token

    @users = []
    @tokens = []
    @groups = []

    def get_cookie_info
      {:secure=>false, :domain=>".twcrowdtest.com"}
    end
    def authenticate_application(name = nil, password = nil)
      "MOCKAPPTOKEN"
    end

    def authenticate_user name, password, factors = nil
      (user = find_user_by_name(name)) && user.password && user.password == password ? new_user_token(name) : nil
    end
    def create_user_token name
      new_user_token(name) if find_user_by_name(name)
    end
    def invalidate_user_token token
      tokens.delete token
    end
    def is_valid_user_token? token, factors = nil
      tokens.include? token
    end
    def find_all_user_names
      users.map{|u| u.username}
    end
    def find_user_by_name name
      users.detect{|u| u.username == name}
    end
    alias_method :find_user_with_attributes_by_name, :find_user_by_name

    def find_user_by_token token
      token && tokens.include?(token) && (name = /.+-TOKENFOR-(.+)$/.match(token)) && name[1] && find_user_by_name(name[1])
    end
    def find_username_by_token token
      (user = find_user_by_token(token)) && user.username
    end
    def find_user_by_email email
      users.detect{|u| u.email == email}
    end
    def search_users_by_email email
      users.select{|u| u.email =~ /#{email}/}
    end
    def search_users criteria, limit=0, start=0
      users = users()
      criteria.each do |search_key, search_val|
        users = users.select do |user|
          val = user[:"#{search_key}"]
          val && val.downcase.include?(search_val.downcase)
        end
      end
      users
    end
    def add_user user, credential
      if user && user.username && !find_user_by_name(user.username)
        user.password = credential
        self.class.users << user
        user
      end
    end
    def remove_user name
      user = users.delete(find_user_by_name(name))
      tokens.reject!{|t| t =~ /.+-TOKENFOR-#{user.username}/} if user && user.username
    end
    def update_user_credential name, credential, encrypted = false
      if user = find_user_by_name(name)
        user.password = credential
      end
    end
    def update_user_attribute user, name, value
      if user = find_user_by_name(user)
        user[name] = value
      end
    end
    def update_user user
      return unless user.dirty?

      attrs_to_update = user.dirty_attributes
      return if attrs_to_update.empty?

      stored_user = find_user_by_name(user.username)
      return if stored_user.blank?

      attrs_to_update.each do |a|
        stored_user[a] = user.send(a)
      end
    end

    def is_group_member? group, user
      group = find_group_by_name(group) unless group.is_a?(SimpleCrowd::Group)
      !!(group && group.members.detect{|m| m == user})
    end
    def find_group_by_name name
      groups.detect{|g| g.name == name}
    end
    def find_all_group_names
      groups.map{|g| g.name}
    end

    private
    def new_user_token username
      random_token(username).tap{|t| tokens << t}
    end
    def random_token username
      "#{rand(36**10).to_s(36)}-TOKENFOR-#{username}"
    end

    def tokens; self.class.tokens; end
    def users; self.class.users; end
    def groups; self.class.groups; end

  end
end
