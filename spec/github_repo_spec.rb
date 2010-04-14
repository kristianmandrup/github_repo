require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# describe "GithubRepo" do
#   it "works" do
#     api = GithubApi.new
#     res = api.tags 'github_thor_tasks'
#     puts res.inspect
# 
#     res = api.branches 'github_thor_tasks'
#     puts res.inspect
#   end
# end

describe "GithubRepo" do
  it "works" do        
    api = GithubApi.new
    api.log_on
#    res = api.create 'hello2', :description => 'my hello2', :homepage => 'my homepage2'  
    # puts api.delete! 'hello2'
    # api.authenticated do
    #   clone_user = api.user
    #   repo = clone_user.repositories.find 'new_hello'    
    #   url = api.get_clone_url(repo, clone_user)    
    #   puts repo
    #   puts url
    # end

    res = api.create 'hello', :description => 'my hello', :homepage => 'my homepage' 
    # puts res
    # # puts Dir.pwd
    # api.init_repo 'hello'
    # puts res
    # api.rename! 'hello', 'new_hello'
    # res = api.rename 'hello', 'new_hello'
    # puts res
  end
end                            


# Running “github_repo_spec.rb”…
# ruby 1.9.1p378 (2010-01-10 revision 26273) [i386-darwin10.2.0]
# Theme:  
# W, [2010-04-13T15:40:17.884494 #91255]  WARN -- : Using in memory store
# F
# 
# 1) GithubRepo works
#     Failure/Error: res = api.create 'hello', :description => 'my hello', :homepage => 'my homepage'
#     Github returned status 403, you may not have access to this resource.
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/api.rb:129:in `rescue in get'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/api.rb:117:in `get'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/api.rb:100:in `find'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/resource.rb:41:in `find'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/repository.rb:82:in `find'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi/repository_set.rb:7:in `find'
#     # /Users/kristianconsult/Development/Languages/Ruby/Apps/Gems/github_repo/lib/github_repo.rb:74:in `block in create'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi.rb:33:in `block in authenticated'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi.rb:63:in `authenticated_with'
#     # /Users/kristianconsult/.rvm/gems/ruby-1.9.1-p378/gems/octopi-0.2.8/lib/octopi.rb:32:in `authenticated'
#     # /Users/kristianconsult/Development/Languages/Ruby/Apps/Gems/github_repo/lib/github_repo.rb:73:in `create'
#     # /Users/kristianconsult/Development/Languages/Ruby/Apps/Gems/github_repo/spec/github_repo_spec.rb:19:in `block (2 levels) in <main>'
# 
# 
# Finished in 3.542207 seconds
# 1 example, 1 failures
# GitHub returned status 403. Retrying request.
# copy output
# Program exited with code #1 after 4.91 seconds.
#    
# 
