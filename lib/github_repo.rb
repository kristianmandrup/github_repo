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

  class DeleteError < StandardError 
  end
  class CreateError < StandardError 
  end
  class RenameError < StandardError 
  end
  class CloneError < StandardError 
  end
  class FirstCommitError < StandardError 
  end
  class FirstPushOriginError < StandardError 
  end         
  class InitRepoError < StandardError 
  end
  class FindError < StandardError 
  end


  attr_accessor :config

  def initialize()
    @config ||= configure 
  end

  def delete!(name)                  
    begin             
      if !user.repositories.find(name)
        puts "repo #{name} not found"
        return nil 
      end     
      delete_it!(name) 
    rescue Octopi::APIError 
      return nil
    end
  end

  def delete_it!(name) 
    begin
      puts "deleting repo: #{name}"
      result = post "http://github.com/api/v2/yaml/repos/delete/#{name}"
      token = result.parse_single_result('delete_token')                               
      return true if token && token.length > 20
      raise DeleteError, "delete error" if !token
      status = post "http://github.com/api/v2/yaml/repos/delete/#{name}", 'delete_token' => token 
      return true if status.to_s.length > 100
    rescue Octopi::APIError 
      puts "delete error!"
      raise DeleteError, "delete error"
    end
  end

  def user(user_name = nil)
    if user_name 
      User.find(user_name) 
    else      
      authenticated do
        Api.api.user
      end
    end
  end
  
  def clone(repo_name, user_name = nil, clone_name = nil)
    begin
      puts "cloning: #{repo_name}"
      clone_user = user(user_name)
      repo = clone_user.repositories.find(repo_name)    
      url = get_clone_url(repo, clone_user)
      name = clone_name ? clone_name : repo_name 
      `git clone #{url} #{name}`
      url
    rescue Octopi::APIError
      raise CloneError
    end
  end    

  def get_clone_url(repo, user)   
    # puts "user: '#{user}' == repo_user: '#{repo.owner.login}', #{user.to_s == repo.owner.login.to_s}"
    url = user.to_s == repo.owner.login.to_s ? "git@github.com:" : "git://github.com/"
    url += "#{repo.owner}/#{repo.name}.git"
  end
  
  def clone_url(repo_name, user_name = nil, retries = 2)
    begin   
      authenticated do
        clone_user = user(user_name)
        repo = clone_user.repositories.find(repo_name)    
        get_clone_url(repo, clone_user)
      end
    rescue Octopi::APIError 
      return "git://github.com/#{repo.owner}/#{repo.name}.git" if retries == 0     
      puts "retry get clone url for #{repo_name} in 20 secs"
      sleep 10                             
      clone_url(repo_name, user_name, retries -1)

    end
  end

  def create(name, options = {})           
    puts "creating repo: #{name}"
    authenticated do
      begin
        if user.repositories.find(name)
          puts "no need to create #{name}, since it already exist!"
          true
        end
      rescue Octopi::APIError
        create_it(name, options)
      end
    end
  end

  def create_it(name, options = {}, retries = 2)
    begin  
      status = nil
      authenticated do 
        puts "configure repo options"         
        repo_options = {:name => name}
        [:description, :homepage ].each{|o| repo_options[o] = options[o] if options[o]}
        repo_options[:public] = 0 if options[:private]                    
        puts repo_options.inspect   
        puts "create it"
        status = Repository.create(repo_options)
        sleep 10 
        puts "created ok: #{status}"              
        status.to_s == name ? status : nil
      end
    rescue Octopi::APIError 
      puts "create error: #{status}"
      nil
    ensure
      if status.to_s == name
        begin
          "was error but also status: #{status}, so returning status"                    
          return status
        rescue Octopi::APIError          
          "retry created repo in 10 secs"
          raise CreateError if retries == 0
          sleep 10 
          return create_it(name, options, retries -1)
        end
      else
        puts "bad status #{status}, should be #{name} - try again!"
        return create_it(name, options, retries -1)        
      end   
    end
  end

  def first_commit(msg = 'first commit')
    begin
      puts "first commit"
      `git init`
      `touch README`    
      `git add .`
      `git commit -m '#{msg}'`
    rescue
      raise FirstCommitError
    end      
  end    

  def first_push_origin(name) 
    begin
      puts "first push origin"    
      origin = clone_url(name) 
      `git remote rm origin`   
      `git remote add origin #{origin}`
      `git push origin master`
    rescue
      raise FirstPushOriginError
    end      
  end    

  def init_repo(name, overwrite = true)  
    begin
      if File.directory?(name) && overwrite
        puts "removing local repo: #{name}"
        FileUtils.rm_rf(name) 
      end
      clone name
      FileUtils.cd name do
        first_commit
        first_push_origin name
      end  
      puts "init repo complete!"
    rescue
      raise InitRepoError
    end
  end


  def rename!(repo_name, new_repo_name, user_name = nil, overwrite = true)
    begin
      delete!(new_repo_name) if overwrite   
      puts "waiting 20 secsfor delete to take effect before creating new repo"
      sleep 20   
      return nil if !create(new_repo_name)   
      puts "created new repo: #{new_repo_name}"
      
      # clone old repo
      puts "current dir: #{Dir.pwd}"
      if File.directory?(repo_name) 
        if overwrite
          puts "removing local repo: #{repo_name}"
          FileUtils.rm_rf(repo_name)  
          old_clone_url = clone(repo_name, user_name)                  
        else
          old_clone_url = clone_url(repo_name, user_name)                 
        end
      else
        old_clone_url = clone(repo_name, user_name)                  
      end        
      puts "cloned old repo from : #{old_clone_url}"
      # create new repo with new name
      raise RenameError, "Error getting hold of old repository" if !old_clone_url

      puts "get clone_url for new repo: #{repo_name}"
      new_clone_url = clone_url(new_repo_name, user_name)                 
      raise RenameError, "Error getting new repository url for: #{new_repo_name}" if !new_clone_url
      
      # change remote origin of repo
      puts "current dir: #{Dir.pwd}"      
      return "no local clone dir for #{repo_name}" if !File.directory? repo_name 
      FileUtils.cd repo_name do 
        puts "update old local repo to point to new repo" 
        `git remote rm origin`      
        puts "removed old origin"
        `git remote add origin #{new_clone_url}`
        puts "added new origin"
        `git push origin master --force`
        puts "pushed to new origin master: #{new_clone_url}"      
        status = delete!(repo_name)
        puts "old repo #{repo_name} deleted" if status              
      end
      FileUtils.rm_rf repo_name
      puts "old local repo deleted"

      puts "making sure old repo is deleted"
      puts delete!(repo_name)                          
    rescue StandardError => e 
      puts e
      true
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
  

