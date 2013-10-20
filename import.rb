require 'git'
require './git-stats'

stats = GitStats::Repository.new
#stats.reset

git = Git.open stats.path

until2 = Time.now
since = stats.last_commit_date

while true
    commits = git.log.until until2.to_s
    if not since.nil? then
        commits.since Time.at(since.to_i + 1).to_s
    end

    if commits.size == 0 then
        break
    end

    commits.each do |commit|
        puts commit.date
        stats<< commit
    end
    stats.first_commit_date = commits.last.date
    stats.last_commit_date = commits.first.date

    until2 = Time.at(commits.last.date.to_i - 1)
end
