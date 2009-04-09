module NavigationHelpers
  
  def path_to(page_name)
        
    case page_name
    
    when /the login form/i
      new_user_session_path        
    
    # Add more page name => path mappings here
    
    else
      raise "Can't find mapping from \"#{page_name}\" to a path."
    end
  end
end

World do |world|
  world.extend NavigationHelpers
  world
end
