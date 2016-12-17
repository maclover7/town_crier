require 'sinatra/base'
require 'tilt/erb'
require 'octokit'
require 'travis'
require 'action_view'
require 'action_view/helpers'

module TownCrier
  class Application < ::Sinatra::Application
    include ::ActionView::Helpers::DateHelper

    configure do
      set :views, './views'
    end

    configure :production do
      enable :logging
    end

    OCTOKIT_CLIENT = Octokit::Client.new(access_token: ENV['GITHUB_OAUTH_TOKEN'])

    get '/' do
      erb :index
    end

    get '/data/ecosystem' do
      projects = [
        { name: 'codetriage/codetriage' },
        { name: 'discourse/discourse' },
        { name: 'airblade/paper_trail' },
        { name: 'rspec/rspec-rails' }
      ]

      projects.each do |p|
        repo = Travis::Repository.find(p[:name])
        jobs = repo.last_build.jobs
        build = jobs.find { |j| valid_job?(j) }
        p[:target_url] = "https://travis-ci.org/#{p[:name]}/jobs/#{build.id}"
        p[:state] = build.state
      end

      erb :details_ecosystem, locals: { projects: projects }, layout: false
    end

    get '/data/master' do
      @commits = []
      OCTOKIT_CLIENT.commits(ENV['REPO'], 'master').each { |c| @commits << [c] }

      @commits.each do |commit|
        if commit[0].commit.message.include?('ci skip') || commit[0].commit.message.include?('skip ci')
          commit << { target_url: '', state: 'n/a' }
        else
          commit << (OCTOKIT_CLIENT.status(ENV['REPO'], commit[0].sha)[:statuses].last || { target_url: '', state: 'n/a' })
        end
      end

      erb :details_master, locals: { commits: @commits }, layout: false
    end

    private

    def valid_job?(job)
      (job.config['rvm'].to_f >= 2.3) &&
      (
        job.config['env'] == 'RAILS_MASTER=1' ||
        # rspec/rspec-rails
        job.config['env'] == 'RAILS_VERSION=master' ||
        # aiblade/paper_trail
        (job.config['gemfile'] && job.config['gemfile'] == 'gemfiles/ar_master.gemfile')
      )
    end
  end
end
