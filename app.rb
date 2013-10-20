require 'sinatra'
require './git-stats'
require 'securerandom'
require 'json'

helpers do
    def partial (template, locals = {})
        erb(template, :layout => false, :locals => locals)
    end
end

get '/' do
    @repository = GitStats::Repository.new

    @select = 'general'
    erb :index
end

get '/activity' do
    @repository = GitStats::Repository.new

    @select = 'activity'
    erb :activity
end

get '/contributors' do
    @repository = GitStats::Repository.new

    @select = 'contributors'
    erb :contributors
end

