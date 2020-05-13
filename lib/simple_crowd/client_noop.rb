# Client with NOOP implementations
module SimpleCrowd
  class ClientNoop
    def get_cookie_info
      {}
    end
    def authenticate_application(name = nil, password = nil)
      "NOOP"
    end

    def authenticate_user name, password, factors = nil
    end
    def create_user_token name
    end
    def invalidate_user_token token
    end
    def is_valid_user_token? token, factors = nil
    end
    def find_all_user_names
      []
    end
    def find_user_by_name name
    end
    alias_method :find_user_with_attributes_by_name, :find_user_by_name

    def find_user_by_token token
    end
    def find_username_by_token token
    end
    def find_user_by_email email
    end
    def search_users_by_email email
    end
    def search_users criteria, limit=0, start=0
      []
    end
    def add_user user, credential
    end
    def remove_user name
    end
    def update_user_credential name, credential, encrypted = false
    end
    def update_user_attribute user, name, value
    end
    def update_user user
    end

    def is_group_member? group, user
    end
    def find_group_by_name name
    end
    def find_all_group_names
      []
    end
  end
end
