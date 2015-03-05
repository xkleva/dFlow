module Requests
  module JsonHelpers
    def json
      unless @last_response_body === response.body
        @json = nil
      end
      @last_response_body = response.body
      @json ||= JSON.parse(response.body)
    end

    def login_users
      @admin_user = create(:admin_user)
      @admin_user_token = @admin_user.generate_token.token
      @operator_user = create(:operator_user)
      @operator_user_token = @operator_user.generate_token.token
      @api_key_user = create(:api_key_user)
    end
  end
end
