Git Stats
=========

Git Stats is a tools to display stats about git reprositories.


Dependances
-----------------

* sinatra
* git
* redis


Setup
-----------------

1. Install ruby and all dependancies (see above)

2. Rename `config.yml-dist` in `config.yml`, then edit it (in particular, informations related to Git repository):

        name: My awesome project
        path: /path/to/your/repository

3. Run script to import stats

        ruby import.rb
        
4. Launch application:

        ruby app.rb

4. Go to [http://localhost:4567](http://localhost:4567)
