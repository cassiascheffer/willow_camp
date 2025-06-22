class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    begin
      response = LoopsSdk::Transactional.send(
        transactional_id: "cmc7lohm60o5yxs0isjsb6cka",
        email: user.email_address,
        data_variables: {
          resetPasswordUrl: edit_password_url(user.reset_password_token)
        }
      )
      Rails.logger.info("Loops password reset email sent: #{response}")
    rescue LoopsSdk::APIError => e
      Honeybadger.notify(e)
      Rails.logger.error("Loops API Error: #{e.json["message"]} (Status: #{e.statusCode})")
    end
  end
end
