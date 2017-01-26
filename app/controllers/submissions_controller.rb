class SubmissionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :thank_you]
  layout 'dashboard', only: [:valid, :rated, :to_rate, :rejected, :results]

  def valid
    submissions_valid = SubmissionRepository.new.valid

    render :list, locals: { submission_presenters: create_submission_presenters(submissions_valid),
      show_average: true, show_rates_count: true }
  end

  def rejected
    submissions_rejected = SubmissionRepository.new.rejected

    render :list, locals: { submission_presenters: create_submission_presenters(submissions_rejected),
      show_average: false, show_rates_count: false }
  end

  def to_rate
    submissions_to_rate = SubmissionRepository.new.to_rate

    render :list, locals: { submission_presenters: create_submission_presenters(submissions_to_rate),
      show_average: false, show_rates_count: true }
  end

  def results
    submissions_accepted = SubmissionRepository.new.accepted
    submissions_waitlist = SubmissionRepository.new.waitlist

    render :results, locals: {
      submissions_accepted: submissions_accepted,
      submissions_waitlist: submissions_waitlist
    }
  end

  def show
    submission = Submission.find(params[:id])
    submission_presenter = SubmissionPresenter.new(submission, submission.rates, SubmissionRepository.new)
    rate_checker = RateChecker.new(submission, current_user.id)

    rate_presenters = create_rate_presenters(submission.rates)
    comment_presenters = create_comment_presenters(submission.comments)

    render :show, locals: {
      comment: Comment.new,
      submission: submission,
      comment_presenters: comment_presenters,
      rate_presenters: rate_presenters,
      submission_presenter: submission_presenter,
      current_user_rate_value: rate_checker.current_user_rate_value
    }
  end

  def new
    if Setting.preparation_period?
      render :preparation
    elsif Setting.registration_period?
      submission = Submission.new
      footer_presenter = FooterPresenter.new(Setting.get)
      render :new, locals: { submission: submission, footer_presenter: footer_presenter }
    else
      render :closed
    end
  end

  def thank_you
  end

  def create
    submission = Submission.new(submission_params)

    if submission.valid?
      submission_rejector = SubmissionRejector.new.reject_if_any_rules_broken(submission)
      submission.save

      redirect_to submissions_thank_you_url
    else
      footer_presenter = FooterPresenter.new(Setting.get)
      render :new, locals: { submission: submission, footer_presenter: footer_presenter }
    end
  end

  def destroy
    submission = Submission.find(params[:id])
    submission.destroy

    redirect_to submissions_url, notice: 'Submission was successfully destroyed.'
  end

  private
    def submission_params
      params.require(:submission).permit(:full_name, :email, :age,
      :codecademy_username, :description, :html, :css, :js, :ror, :db,
      :programming_others, :english, :operating_system, :first_time, :goals,
      :problems)
    end

    def create_rate_presenters(rates)
      rates.map { |rate| RatePresenter.new(rate, rate.user) }
    end

    def create_comment_presenters(comments)
      comments.map { |comment| CommentPresenter.new(comment, comment.user) }
    end

    def create_submission_presenters(submissions)
      submissions.map { |submission| SubmissionPresenter.new(submission, submission.rates, SubmissionRepository.new) }
    end
end
