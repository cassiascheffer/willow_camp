class LoopsDeviseMailer < ApplicationMailer
  def reset_password_instructions(record, token, opts = {})
    @user = record
    @token = token

    send_loops_email(
      transactional_id: "cmc7lohm60o5yxs0isjsb6cka", # Password reset template
      email: record.email,
      data_variables: {
        resetPasswordUrl: edit_user_password_url(reset_password_token: token),
        userName: record.name || record.email
      },
      email_type: "password_reset"
    )
  end

  def confirmation_instructions(record, token, opts = {})
    # Confirmation is not enabled for this app
    Rails.logger.info("Confirmation instructions requested for #{record.email} but :confirmable module is not enabled")
    nil
  end

  def email_changed(record, opts = {})
    send_loops_email(
      transactional_id: "cmc7molkm2l17wy0id6jpaz4g",
      email: record.email_was, # Send to old email
      data_variables: {
        oldEmail: record.email_was,
        newEmail: record.email
      },
      email_type: "email_changed"
    )

    Rails.logger.info("Email changed notification would be sent to #{record.email_was}")
    nil
  end

  def password_change(record, opts = {})
    send_loops_email(
      transactional_id: "cmc7msqvt075c1y0i50wkvkb5",
      email: record.email,
      data_variables: {
        changeTime: Time.current.strftime("%B %d, %Y at %I:%M %p")
      },
      email_type: "password_changed"
    )

    Rails.logger.info("Password change notification would be sent to #{record.email}")
    nil
  end

  def unlock_instructions(record, token, opts = {})
    # Account locking is not enabled for this app
    Rails.logger.info("Unlock instructions requested for #{record.email} but :lockable module is not enabled")
    nil
  end

  private

  def send_loops_email(transactional_id:, email:, data_variables:, email_type:)
    begin
      response = LoopsSdk::Transactional.send(
        transactional_id: transactional_id,
        email: email,
        data_variables: data_variables
      )
      Rails.logger.info("Loops #{email_type} email sent successfully to #{email}: #{response}")
    rescue LoopsSdk::APIError => e
      Honeybadger.notify(e, context: {
        email_type: email_type,
        transactional_id: transactional_id
      })
      Rails.logger.error("Loops API Error for #{email_type}: #{e.json["message"]} (Status: #{e.statusCode})")
    rescue => e
      Honeybadger.notify(e, context: {
        email_type: email_type,
        transactional_id: transactional_id
      })
      Rails.logger.error("Unexpected error sending #{email_type} email: #{e.message}")
    end
    nil
  end
end
