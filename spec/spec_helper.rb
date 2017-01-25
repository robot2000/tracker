
RSpec.configure do |config|

  config.expect_with :rspec do |expectations|
   
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  
  config.mock_with :rspec do |mocks|
    
    mocks.verify_partial_doubles = true
  end

  
  config.shared_context_metadata_behavior = :apply_to_host_groups


  def ss
    screenshot_and_open_image
  end

  def sp
    save_and_open_page
  end

  def office_group
    Group.find_by(code: 'office') || create(:group, :office)
  end

  def position_group
    Group.find_by(code: 'position') || create(:group, :position)
  end

end
