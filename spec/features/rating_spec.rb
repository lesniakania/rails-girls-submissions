include Warden::Test::Helpers
Warden.test_mode!

describe "the rating process" do
  let!(:submission) { FactoryGirl.create(:submission) }
  let!(:user) { FactoryGirl.create(:user) }

  it "visits submission page, finds and clicks rate button" do
    login_as(user, scope: :user)
    visit submission_path(submission)
    expect{click_button '4'}.to change(submission.rates, :count).by(1)
  end
end

Warden.test_reset!
