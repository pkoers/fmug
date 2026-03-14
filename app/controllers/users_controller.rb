class UsersController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: :admin

  def index
    @users = User.order(:first_name, :last_name)
  end

  def destroy
    user = User.find(params[:id])
    deleting_self = user == current_user

    unless deleting_self || current_user.admin?
      redirect_to users_path, alert: "You can only delete your own account."
      return
    end

    if deleting_self && current_user.admin?
      redirect_to users_path, alert: "Admins cannot delete their own account."
      return
    end

    user.destroy!
    reset_session if deleting_self

    if deleting_self
      redirect_to root_path, notice: "Your account has been deleted."
    else
      redirect_to users_path, notice: "#{user.first_name} #{user.last_name} has been deleted."
    end
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
