require 'octopi'
require 'git'
require 'yaml'
require 'github_util'

module GithubParser
  def parse_single_result(key)
    self.body[/#{Regexp.escape(key)}:\s(.*)/, 1]
  end

  def parse_result(key)
    result = self.body.gsub("\n", '')         
    token = result[/#{Regexp.escape(key)}:(.*)/, 1]
    token.split("- ").reject{|e| e == ' ' || e.match('{}') }.collect{|e| e.strip}
  end
end  

class GithubApi
  include Octopi 
  include GithubUtil

  attr_accessor :config

  def initialize()
    @config ||= configure 
  end

  def delete!(name)                  
    begin
      result = post "http://github.com/api/v2/yaml/repos/delete/#{name}"
      token = result.parse_single_result('delete_token')  

      status = post "http://github.com/api/v2/yaml/repos/delete/#{name}", 'delete_token' => token      
    rescue Error => e
      puts "ERROR: #{e}"
    end
  end

  def clone(repo_name, user_name = nil, clone_name = nil)
    user = user_name ? User.find(user_name) : Api.api.user
    raise UserNotFound if !user
    repo = user.repositories.find(repo_name)    
    url = repo.clone_url
    name = clone_name ? clone_name : repo_name 
    `git clone #{url} #{name}`
    url
  end    
  
  def clone_url(repo_name)
    repo = user.repositories.find(repo_name)    
    repo.clone_url
  end


  def create(name)           
    authenticated do
      repo_options = {:name => name}
      [:description, :homepage ].each{|o| repo_options[o] = options[o] if options[o]}
      repo_options[:public] = 0 if options[:private]                    
      Repository.create(repo_options)               
    end
    clone_url(name)
  end

  def first_commit
    `git init`
    `touch README`    
    `git add .`
    `git commit -am '#{msg}'`
  end    

  def first_push_origin(name)
    origin = clone_url(name)    
    `git remote add origin #{origin}`
    `git push origin master`
  end    


  def rename!(repo_name, new_repo_name, user_name = nil)
    begin
      # clone old repo
      old_clone_url = clone(repo_name, user_name)    
      # create new repo with new name
      new_clone_url = create(new_repo_name)          
      # change remote origin of repo
      Dir.cd repo_name
      `git remote add origin #{new_clone_url}`
      `git push origin master`
      delete!(repo_name)
    rescue Error => e
      puts e
    end      
  end

  def fork(repo, options = {})                               
    post_repo_user 'repos/fork', options
  end    
                        
  def collaborators(repo, options = {})    
    post_repo_show repo, 'collaborators', options    
  end

  def languages(repo, options = {})    
    post_repo_show repo, 'languages', options
  end

  def tags(repo, options = {})    
    post_repo_show repo, 'tags', options
  end

  def branches(repo, options = {})    
    post_repo_show repo, 'branches', options
  end
    
end
  

