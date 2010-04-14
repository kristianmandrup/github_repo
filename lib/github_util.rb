module GithubUtil
  def configure

    git_config = Git.global_config
    user_name       = git_config['user.name']
    user_email      = git_config['user.email']
    github_username = git_config['github.user']
    github_token    = git_config['github.token']

    {:name => github_username, :token => github_token, :login => github_username}
  end
   
  def info(msg) 
    puts msg if log_level > 0
  end

  def log(msg)    
    puts msg if log_level > 1
  end


  def post(path, options = {})
    opts = {'login' => config[:login], 'token' => config[:token]}        
    res = Net::HTTP.post_form URI.parse(path), opts.merge(options) 
    res.extend(GithubParser)
  end

  def post_repo_user(api_path, repo, action, options = {})
    user = options[:user] ? options[:user] : config[:name]
    path = 'http://github.com/api/v2/yaml/' 
    path << api_path
    path << "/#{user}/#{repo}"
    path << "/#{action}" if action
    post path, options
  end

  def post_repo_show(repo, action, options = {})
    res = post_repo_user 'repos/show', repo, action, options
    res.parse_result(action)
  end
end