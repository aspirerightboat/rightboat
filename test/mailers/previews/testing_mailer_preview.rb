class TestingMailerPreview < ActionMailer::Preview

  def test_gmail
    TestingMailer.test_gmail
  end

  def test_amazon
    TestingMailer.test_amazon
  end
end
