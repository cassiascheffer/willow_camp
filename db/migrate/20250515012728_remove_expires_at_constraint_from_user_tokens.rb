class RemoveExpiresAtConstraintFromUserTokens < ActiveRecord::Migration[8.0]
  def change
    # Remove the constraint that prevents past dates in expires_at field
    remove_check_constraint :user_tokens, name: "check_expires_at_in_future"
  end
end
