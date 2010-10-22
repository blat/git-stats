require 'rubygems'
require 'date'
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
    @by_date = Array.new(@since, 0)
    @by_hour = Array.new(24, 0)
    @by_day_of_week = Array.new(7, 0)

    commits = git.log.since(@since.to_s + ' days ago')
    commits.each do |commit|

        author = commit.author.name
        if not @by_author.key?(author) then
            @by_author[author] = 0
        end
        @by_author[author] += 1

        date = Date.strptime(commit.date.strftime("%Y-%m-%d"), "%Y-%m-%d");
        @by_date[Date.today - date] += 1
        @by_hour[commit.date.strftime("%H").to_i] += 1
        @by_day_of_week[date.wday] += 1

    end

    @repositories = Dir.open('data/').sort - ['.', '..']
    erb :stats
end

