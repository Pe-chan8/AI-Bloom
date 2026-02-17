namespace :devise do
  desc "Send confirmation instructions (development helper)"
  task :send_confirmation, [:user_id] => :environment do |_, args|
    Rails.application.reload_routes!
    user = User.find(args[:user_id])
    user.send_confirmation_instructions
    puts "sent confirmation to user_id=#{user.id} (#{user.email})"
  end
end
