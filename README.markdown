Git Stats
=========

Git Stats is a tools to display stats about git reprositories.


Dependances
-----------------

* sinatra
* git


Setup
-----------------

1. Install ruby and all dependancies (see above)

2. Build data directory and clone some git reprositories:

        mkdir data
        cd data
        git clone https://github.com/path/to/repository1.git
        git clone https://github.com/path/to/repository2.git
        git clone https://github.com/path/to/repository3.git

3. Launch application:

        ruby git-stats.rb

4. Go to [http://localhost:4567](http://localhost:4567)
