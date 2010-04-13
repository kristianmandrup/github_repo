# github_repo ##

Library to enable automation of common github repository tasks. 
This library is a response to some problems I had getting Octopi to work correctly for repository tasks. 
I use the Octopi API in some cases, but implement my own Http post calls in most cases.   

## Rename ##

Renames a github repo

Rename [old-name] [new-name]

1. Deletes any existing github repository [new-name] (if overwrite option)
2. Creates a new repository called [new-name]
3. Clones the github repository [old-name] locally
4. Deletes the github repository [old-name]
5. Changes origin of the local [old-name] repository to point to the github repository [new-name]
6. Push the local repository to the github repository [new-name] 
7. Makes sure the github repository [old-name] was deleted!      
8. If the repository [new-name] exists, delete the local repo (only if option set to do so!) 

Note: Currently this task contains a lot of code to retry when things go wrong some some reason. 
The github API is still pretty unstable! And suffers from some timeout and caching issues, which requires a lot of care and exception handling!
Feel free to improve it! 

## Other Github tasks ##

* Delete 
* Create
* Get clone url
* Clone
* Fork
* Collaborators
* Languages
* Tags
* Branches
* First commit
* First origin push
* Init repository

## Note on Patches/Pull Requests ##
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright ##

Copyright (c) 2010 Kristian Mandrup. See LICENSE for details.
