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


  attr_accessor :config, :log_level

  def initialize(options = {})
    @config = configure
    @log_level = options[:log_level] || 0
  end

  def log_on   
    self.log_level = 1
  end    

  def verbose_log_on
    self.log_level = 2
  end    


  def log_off
    self.log_level = 0
  end    

  def delete!(name)                  
    begin             
      if !user.repositories.find(name)
        info "repo #{name} not found"
        return nil 
      end     
      delete_it!(name) 
    rescue Octopi::APIError 
      return nil
    end
  end

  def delete_it!(name) 
    begin
      info "deleting repo: #{name}"
      result = post "http://github.com/api/v2/yaml/repos/delete/#{name}"
      token = result.parse_single_result('delete_token')                               
      return true if token && token.length > 20
      raise DeleteError, "delete error" if !token
      status = post "http://github.com/api/v2/yaml/repos/delete/#{name}", 'delete_token' => token 
      return true if status.to_s.length > 100
      log "repo #{name} deleted ok"
      status
    rescue Octopi::APIError 
      log "delete error!"
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
      info "cloning: #{repo_name}"
      clone_user = user(user_name)
      repo = clone_user.repositories.find(repo_name)    
      url = get_clone_url(repo, clone_user)
      name = clone_name ? clone_name : repo_name 
      `git clone #{url} #{name}`  
      log "cloned #{repo_name} ok"
      return url
    rescue Octopi::APIError
      raise CloneError
    end
  end    

  def get_clone_url(repo, user)   
    # log "user: '#{user}' == repo_user: '#{repo.owner.login}', #{user.to_s == repo.owner.login.to_s}"
    url = user.to_s == repo.owner.login.to_s ? "git@github.com:" : "git://github.com/"
    url += "#{repo.owner}/#{repo.name}.git"
  end
  
  def clone_url(repo_name, user_name = nil, options = {:retries => 3} )
    begin   
      authenticated do
        clone_user = user(user_name)
        repo = clone_user.repositories.find(repo_name)    
        get_clone_url(repo, clone_user)
      end
    rescue Octopi::APIError 
      return "git://github.com/#{repo.owner}/#{repo.name}.git" if options[:retries] == 0     
      info "retry get clone url for #{repo_name} in 10 secs"
      sleep 10        
      options.merge! :retries => options[:retries] -1                           
      clone_url(repo_name, user_name, options)
    end
  end

  def create(name, options = {})           
    log "creating repo: #{name}"
    authenticated do
      begin
        if user.repositories.find(name) 
          unless options[:overwrite]
            info "repo #{name} not created since it already exists"
            return true
          else
            info "repo #{name} already exists, but will be overwritten with new repo!"            
            delete!(name, options)
            create(name, options)
          end
        end
      rescue Octopi::APIError
        create_it(name, options)
      end
    end
  end

  def create_it(name, options = {:retries => 2})
    begin  
      status = nil
      authenticated do 
        repo_options = {:name => name}
        [:description, :homepage ].each{|o| repo_options[o] = options[o] if options[o]}
        repo_options[:public] = 0 if options[:private]                    
        log repo_options.inspect   
        status = Repository.create(repo_options)
        status.to_s == name ? status : nil
      end
    rescue Octopi::APIError => e 
      info "create error: #{e}"
    ensure
      options.merge! :retries => options[:retries] -1
      if status.to_s == name
        log "created repo ok"
        return status
      else
        info "bad status #{status}, should be #{name} - try again!"
        sleep 32         
        return create_it(name, options )        
      end   
    end
  end

  def first_commit(msg = 'first commit')
    begin
      info "first commit"
      `git init`
      `touch README`    
      `git add .`
      `git commit -m '#{msg}'`            
      log "first push commit completed ok"      
    rescue
      raise FirstCommitError
    end      
  end    

  def first_push_origin(name) 
    begin
      info "first push origin"    
      origin = clone_url(name) 
      `git remote rm origin`   
      `git remote add origin #{origin}`
      `git push origin master`
      log "first push origin completed ok"
    rescue
      raise FirstPushOriginError
    end      
  end    

  def init_repo(name, options = {:overwrite => true})  
    begin
      if File.directory?(name) && options[:overwrite]
        log "removing local repo: #{name}"
        FileUtils.rm_rf(name) 
      end
      clone name
      FileUtils.cd name do
        first_commit
        first_push_origin name
      end  
      log "init repo complete!"
    rescue
      raise InitRepoError
    end
  end


  def rename!(repo_name, new_repo_name, user_name = nil, options = {:overwrite => true})
    begin
      delete!(new_repo_name) if options[:overwrite]   
      info "waiting 20 secs for delete to take effect before creating new repo"
      sleep 20   
      return nil if !create(new_repo_name)   
      log "created new repo: #{new_repo_name}"
      
      # clone old repo
      info "current dir: #{Dir.pwd}"
      if File.directory?(repo_name) 
        if overwrite
          info "removing local repo: #{repo_name}"
          FileUtils.rm_rf(repo_name)  
          old_clone_url = clone(repo_name, user_name)                  
        else
          old_clone_url = clone_url(repo_name, user_name)                 
        end
      else
        old_clone_url = clone(repo_name, user_name)                  
      end        
      log "cloned old repo from : #{old_clone_url}"
      # create new repo with new name
      raise RenameError, "Error getting hold of old repository" if !old_clone_url

      info "get clone_url for new repo: #{repo_name}"
      new_clone_url = clone_url(new_repo_name, user_name)                 
      raise RenameError, "Error getting new repository url for: #{new_repo_name}" if !new_clone_url
      
      # change remote origin of repo
      info "current dir: #{Dir.pwd}"      
      return "no local clone dir for #{repo_name}" if !File.directory? repo_name 
      FileUtils.cd repo_name do 
        info "update old local repo to point to new repo" 
        `git remote rm origin`      
        info "removed old origin"
        `git remote add origin #{new_clone_url}`
        info "added new origin"
        `git push origin master --force`
        log "pushed to new origin master: #{new_clone_url}"      
        status = delete!(repo_name)
        log "old repo #{repo_name} deleted" if status              
      end
      
      FileUtils.rm_rf repo_name if options[:delete_local]
      log "old local repo directory deleted"

      info "making sure old repo is deleted"
      log delete!(repo_name)                          
    rescue StandardError => e 
      log e
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
  

