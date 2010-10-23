require 'rubygems'
require 'date'
require 'digest/md5'
require 'erb'
require 'git'
require 'sinatra'

get '/' do
    @repositories = Dir.open('data/').sort - ['.', '..']
    erb :index
end

get '/:repository' do
    redirect '/' + params[:repository] + '/7'
end

get '/:repository/:since' do
    @repository = params[:repository]
    @since = params[:since].to_i

    git = Git.open('data/' + @repository)

    @by_author = {}

    @by_date = {}
    (0..@since).each do |n|
        @by_date[(Date.today - @since + n).to_s] = 0
    end

    @by_hour = {}
    (0..23).each do |n|
        @by_hour[n.to_s + "h"] = 0
    end

    @by_day_of_week = {}
    (0..6).each do |n|
        @by_day_of_week[Date::DAYNAMES[n]] = 0
    end

    commits = git.log.since(@since.to_s + ' days ago')
    commits.each do |commit|

        author = commit.author.name
        date = DateTime.strptime(commit.date.strftime("%Y-%m-%d %H:%M:%S"), "%Y-%m-%d %H:%M:%S");

        if not @by_author.key?(author) then
            @by_author[author] = 0
        end
        @by_author[author] += 1

        @by_date[date.strftime("%Y-%m-%d")] += 1
        @by_hour[date.hour.to_s + "h"] += 1
        @by_day_of_week[Date::DAYNAMES[date.wday]] += 1

    end

    @repositories = Dir.open('data/').sort - ['.', '..']
    erb :stats
end

