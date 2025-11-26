if Rails.env.production?
  seed_flag = Rails.root.join("tmp", "seed_done.txt")

  unless File.exist?(seed_flag)
    Rails.logger.info "Running seeds in production..."
    begin
      require Rails.root.join("db/seeds.rb")
      File.write(seed_flag, Time.now.to_s)
      Rails.logger.info "Seeds executed successfully."
    rescue => e
      Rails.logger.error "Seed execution failed: #{e.message}"
    end
  end
end