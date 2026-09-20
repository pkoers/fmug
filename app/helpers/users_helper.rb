module UsersHelper
  def user_avatar_source(user)
    return user.photo if user.photo.attached?

    avatar_seed = ERB::Util.url_encode("#{user.first_name}-#{user.last_name}-#{user.id}")
    "https://robohash.org/#{avatar_seed}.png?set=set4&size=180x180"
  end
end
