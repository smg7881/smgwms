class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  layout "session"

  def new
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address],
                                    password: params[:password])
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
