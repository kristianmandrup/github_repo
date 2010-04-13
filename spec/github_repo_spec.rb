require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "GithubRepo" do
  it "works" do
    api = GithubApi.new
    res = api.tags 'github_thor_tasks'
    puts res.inspect

    res = api.branches 'github_thor_tasks'
    puts res.inspect
  end
end
   

TODO:      

TESTS
create repo
initial_commit

rename_repo
- clone old repo
- create new repo with new name
- change remote origin of repo
- push repo to new 
- delete old repo 
