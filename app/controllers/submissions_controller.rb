class SubmissionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:confirm_invitation, :new, :create, :thank_you]

  layout 'admin', only: :show

  def confirm_invitation
    token = params.require(:invitation_token)
    submission = Submission.find_by!(invitation_token: token)

    case submission.invitation_status
    when :not_invited
      raise "A user with invitation_status = :not_invited is in possesion of an invitation token."
    when :confirmed
      render 'invitation_confirmed'
    when :expired
      render 'invitation_expired'
    when :invited
      submission.confirm_invitation!
      render 'invitation_confirmed'
    end
  rescue StandardError => e
    logger.error(e)
    render plain: "Something went wrong. Please make sure the address you are trying to visit
                  is correct, otherwise contact us by replying to the email you received
                  the confirmation link from."
  end

  def show
    submission = Submission.find(params[:id])
    submission_filter = params[:filter].to_sym

    result = SubmissionFilterGuard.new(submission, submission_filter).call
    message = result.message

    # rubocop:disable Style/GuardClause
    if message == :forbidden_filter
      return render file: "public/404.html", status: :not_found
    elsif message == :incorrect_filter
      return redirect_to "/admin/submissions/#{submission_filter}"
    end

    # rubocop:enable Style/GuardClause

    submission_carousel = SubmissionCarousel.build(submission_filter)
    submission_repo = SubmissionRepository.new

    render :show, locals: {
      submission: SubmissionPresenter.build(submission, current_user),
      answers: AnswerPresenter.collection(submission.answers),
      comment: Comment.new,
      comment_presenters: CommentPresenter.collection(submission_repo.comments(submission)),
      rate_presenters: RatePresenter.collection(submission_repo.rates(submission)),
      previous_submission_id: submission_carousel.previous(submission).id,
      next_submission_id: submission_carousel.next(submission).id,
      filter: submission_filter
    }
  end

  def new
    if Setting.preparation_period?
      render :preparation
    elsif Setting.registration_period?
      render :new, locals: {
        submission: Submission.new,
        answers: build_form_answers,
        footer_presenter: SettingPresenter.new(Setting.get),
        show_errors: false
      }
    else
      render :closed
    end
  end

  def thank_you
    render :thank_you
  end

  def create
    submission_creator = SubmissionCreator.build(submission_params, answers_params)
    result = submission_creator.call

    if result.success
      redirect_to submissions_thank_you_url
    else
      render :new, locals: {
        submission: result.object[:submission],
        answers: result.object[:answers],
        footer_presenter: SettingPresenter.new(Setting.get),
        show_errors: true
      }
    end
  end

  private

  def submission_params
    params.require(:submission).permit(
      :full_name, :email, :adult, :description, :english, :operating_system, :first_time, :goals,
      :problems, :gender,
    )
  end

  def answers_params
    result = params.require(:submission)
                   .permit(answers_attributes: [:choice, :question_id])[:answers_attributes]
    result ? result.values : {}
  end

  def build_form_answers
    Question.all.map { |q| Answer.new(question: q) }
  end
end
