RSpec.configure do |config|
  
  # Config copied from http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end
end