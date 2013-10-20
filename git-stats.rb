require 'redis'
require 'date'
require 'digest/md5'
require 'yaml'

module GitStats

    class Cache < ::Redis
        def initialize config
            super :host => config['host'], :port => config['port']
            select config['database']
        end
    end

    class Repository
        def initialize
            config = YAML.load_file('./config.yml')
            @cache = Cache.new config['cache']
            @name = config['repository']['name']
            @path = config['repository']['path']
        end

        def name
            @name
        end

        def path
            @path
        end

        def cache
            @cache
        end

        def reset
            @cache.flushdb
        end

        def first_commit_date
            date = @cache.get 'commit:first'
            if not date.nil? then
                date = Time.at date.to_i
            end
            date
        end

        def first_commit_date= date
            current = first_commit_date
            if current.nil? or current > date then
                @cache.set 'commit:first', date.to_i
            end
        end

        def last_commit_date
            date = @cache.get('commit:last')
            if not date.nil? then
                date = Time.at(date.to_i)
            end
            date
        end

        def last_commit_date= date
            current = last_commit_date
            if current.nil? or current < date then
                @cache.set 'commit:last', date.to_i
            end
        end

        def max_weekly_commits_count
            count = @cache.get 'activity:max'
            count.to_i
        end

        def max_weekly_commits_count= max
            current = max_weekly_commits_count
            if current.nil? or current < max then
                @cache.set 'activity:max', max
            end
        end

        def max_weekly_insertions_count
            count = @cache.get 'activity:insertions:max'
            count.to_i
        end

        def max_weekly_insertions_count= max
            current = max_weekly_insertions_count
            if current.nil? or current < max then
                @cache.set 'activity:insertions:max', max
            end
        end

        def max_weekly_deletions_count
            count = @cache.get 'activity:deletions:max'
            count.to_i
        end

        def max_weekly_deletions_count= max
            current = max_weekly_deletions_count
            if current.nil? or current < max then
                @cache.set 'activity:deletions:max', max
            end
        end

        def commits_count
            @cache.get('commits').to_i
        end

        def contributors_count
            @cache.zcard('contributors')
        end

        def active_days_count
            @cache.scard('days:active')
        end

        def days_count
            days = last_commit_date.to_date - first_commit_date.to_date
            days.to_i
        end

        def average_commits_per_contributor
            commits_count / contributors_count
        end

        def average_commits_per_active_day
            commits_count / active_days_count
        end

        def weekly_activity
            weeks = self.weeks
            activity = @cache.hmget 'activity', weeks

            result = []
            weeks.each_with_index do |week, index|
                result << [week, activity[index].to_i]
            end
            result
        end

        def weekly_lines
            weeks = self.weeks
            insertions = @cache.hmget 'activity:insertions', weeks
            deletions = @cache.hmget 'activity:deletions', weeks

            result = []
            weeks.each_with_index do |week, index|
                result << [week, insertions[index].to_i, deletions[index].to_i]
            end
            result
        end

        def insertions_count
            count = @cache.get 'insertions'
            count.to_i
        end

        def deletions_count
            count = @cache.get 'deletions'
            count.to_i
        end

        def lines_count
            insertions_count - deletions_count
        end

        def activity_per_hours
            hours = []
            (0..23).step do |hour|
                label = hour.to_s + ':00'
                count = @cache.get 'hours:' + hour.to_s
                hours << [label, count.to_i]
            end
            hours
        end

        def activity_per_days
            days = []
            (1..7).step do |day|
                day = day % 7
                count = @cache.get 'days:' + day.to_s
                days << [Date::DAYNAMES[day], count.to_i]
            end
            days
        end

        def activity_per_months
            months = []
            (1..12).step do |month|
                count = @cache.get 'months:' + month.to_s
                months << [Date::MONTHNAMES[month], count.to_i]
            end
            months
        end

        def activity_per_years
            years = []
            (first_commit_date.year .. last_commit_date.year).step do |year|
                count = @cache.get 'years:' + year.to_s
                years << [year.to_s, count.to_i]
            end
            years
        end

        def activity_per_days_and_per_hours
            result = []
            (0..23).step do |hour|
                tmp = [hour.to_s + ':00']
                (0..6).step do |day|
                    count = @cache.get day.to_s + ':' + hour.to_s
                    tmp << count.to_i
                end
                result << tmp
            end
            result
        end

        def contributors
            contributors = []
            @cache.zrevrange('contributors', 0, -1, :with_scores => true).each do |id, commits_count|

                contributor = Contributor.new id
                contributor.repository = self
                contributor.commits_count = commits_count
                contributors << contributor
            end

            contributors
        end

        def << commit
            @cache.incr 'commits' # commits count
            @cache.incr 'hours:' + commit.date.hour.to_s # activity per hours
            @cache.incr 'days:' + commit.date.wday.to_s # activity per days
            @cache.incr 'months:' + commit.date.month.to_s # activity per months
            @cache.incr 'years:' + commit.date.year.to_s # activity per years
            @cache.sadd 'days:active', commit.date.to_date.to_s # active days
            @cache.incr commit.date.wday.to_s + ':' + commit.date.hour.to_s # activity per days and per hours

            week = Repository::week commit.date
            @cache.hincrby 'activity', week, 1 # weekly activity

            stats = commit.diff_parent.stats[:total]
            @cache.incrby 'insertions', stats[:insertions] # insertions count
            @cache.incrby 'deletions', stats[:deletions] # deletions count
            @cache.hincrby 'activity:insertions', week, stats[:insertions] # weekly insertions
            @cache.hincrby 'activity:deletions', week, -stats[:deletions] # weekly deletions

            contributor_id = Contributor.id commit.author
            contributor = Contributor.new contributor_id
            contributor.repository = self
            contributor.name = commit.author.name
            contributor.email = commit.author.email
            contributor << commit
        end

        def weeks
            start = first_commit_date
            stop = last_commit_date

            weeks = []
            while start <= stop do
                weeks << Repository::week(start)
                start += 7*24*3600
            end

            weeks
        end

        def self.week date
            date.to_date.cwyear.to_s + 'W' + date.to_date.cweek.to_s.rjust(2, '0')
        end
    end

    class Contributor

        def initialize id
            @id = id
        end

        def repository= repository
            @repository = repository
        end

        def commits_count
            @commits_count
        end

        def commits_count= commits_count
            @commits_count = commits_count.to_i
        end

        def weekly_activity
            weeks = @repository.weeks
            activity = @repository.cache.hmget 'contributor:' + @id + ':activity', weeks

            result = []
            weeks.each_with_index do |week, index|
                result << [week, activity[index].to_i]
            end
            result
        end

        def weekly_commits_count week
            count = @repository.cache.hget 'contributor:' + @id + ':activity', week
            count.to_i
        end

        def weekly_lines
            weeks = @repository.weeks
            insertions = @repository.cache.hmget 'contributor:' + @id + ':activity:insertions', weeks
            deletions = @repository.cache.hmget 'contributor:' + @id + ':activity:deletions', weeks

            result = []
            weeks.each_with_index do |week, index|
                result << [week, insertions[index].to_i, deletions[index].to_i]
            end
            result
        end

        def weekly_insertions_count week
            count = @repository.cache.hget 'contributor:' + @id + ':activity:insertions', week
            count.to_i
        end

        def weekly_deletions_count week
            count = @repository.cache.hget 'contributor:' + @id + ':activity:deletions', week
            -count.to_i
        end

        def name
            @repository.cache.hget 'contributor:' + @id, 'name'
        end

        def name= name
            @repository.cache.hset 'contributor:' + @id, 'name', name
        end

        def email
            @repository.cache.hget 'contributor:' + @id, 'email'
        end

        def email= email
            @repository.cache.hset 'contributor:' + @id, 'email', email
        end

        def insertions_count
            @repository.cache.hget 'contributor:' + @id, 'insertions'
        end

        def deletions_count
            @repository.cache.hget 'contributor:' + @id, 'deletions'
        end

        def << commit
            @repository.cache.zincrby 'contributors', 1, @id # commits count
            week = Repository::week commit.date
            @repository.cache.hincrby 'contributor:' + @id + ':activity', week, 1 # weekly activity

            stats = commit.diff_parent.stats[:total]
            @repository.cache.hincrby 'contributor:' + @id, 'insertions', stats[:insertions] # insertions count
            @repository.cache.hincrby 'contributor:' + @id, 'deletions', stats[:deletions] # deletions count
            @repository.cache.hincrby 'contributor:' + @id + ':activity:insertions', week, stats[:insertions] # weekly insertions
            @repository.cache.hincrby 'contributor:' + @id + ':activity:deletions', week, -stats[:deletions] # weekly deletions

            @repository.max_weekly_commits_count = weekly_commits_count week
            @repository.max_weekly_insertions_count = weekly_insertions_count week
            @repository.max_weekly_deletions_count = weekly_deletions_count week
        end

        def self.id data
            Digest::MD5.hexdigest data.email
        end
    end

end
