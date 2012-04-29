class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # Extend the standard message generation to accept our custom exception
  def failure_message
    exception = env["omniauth.error"]
    if exception.class == OmniAuth::Error
      error = exception.message
    else
      error   = exception.error_reason if exception.respond_to?(:error_reason)
      error ||= exception.error        if exception.respond_to?(:error)
      error ||= env["omniauth.error.type"].to_s
    end
    error.to_s.humanize if error
  end
 
  def ldap
    # We only find ourselves here if the authentication to LDAP was successful.
    info = request.env["omniauth.auth"]["info"]
    @user = User.find_for_ldap_auth(info)
    if @user.persisted?
      @user.remember_me = true
    end
    sign_in_and_redirect @user
  end

  def google
    omniauth_data = request.env["omniauth.auth"].info
    if omniauth_data["email"] && omniauth_data["email"].ends_with?('c42.in')
      @user = User.find_for_open_id(request.env["omniauth.auth"], current_user)
      if @user.persisted?
        flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.google_data"] = request.env["omniauth.auth"]
        redirect_to new_user_session_path
      end
    else
      flash[:notice] = "Login using C42 Engineering account"
      redirect_to new_user_session_path
    end
  end
end
