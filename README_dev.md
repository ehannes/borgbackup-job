# BATS
This project uses [BATS - Bash Automated Testing System](https://bats-core.readthedocs.io)
(the [bats-core](https://github.com/bats-core/bats-core) release) for unit tests. 

# git submodules
This project uses git submodules for `tests/bats`.  
* To clone repo including the submodules  
  `git clone --recursive ...`
* To download the submodules after cloning  
  `git submodule update --init`
* To sync the submodules to the main repo, e.g. after a dependency change in the main repo  
  `git submodule update --remote`
  
For more guidance on submodules, see for example  
https://www.vogella.com/tutorials/GitSubmodules/article.html