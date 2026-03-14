class UsersController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: :admin

  def index
    @users = User.order(:first_name, :last_name)
  end

  def admin
    user = User.find(params[:id])

    if user == current_user
      redirect_to users_path, alert: "You cannot remove your own admin rights."
      return
    end

    user.update!(admin: ActiveModel::Type::Boolean.new.cast(params[:admin]))

    redirect_to users_path, notice: "#{user.first_name} #{user.last_name} admin access updated."
  end
end
