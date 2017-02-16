class InvitationsMailer < ApplicationMailer
  def invitation_email(submission)
    email = submission.email
    @token = submission.invitation_token
    mail(to: email, subject: 'Your application has been accepted!')
  end

  def reminder_email(submission)
    email = submission.email
    @token = submission.invitation_token
    mail(to: email, subject: 'Your invitation link expires tomorrow!')
  end
end