require 'sinatra/base'
require 'tilt/erb'
require 'octokit'
require 'action_view'
require 'action_view/helpers'

module TownCrier
  class Application < ::Sinatra::Application
    include ::ActionView::Helpers::DateHelper

    configure do
      set :views, './views'
    end

    OCTOKIT_CLIENT = Octokit::Client.new(access_token: ENV['GITHUB_OAUTH_TOKEN'])

    get '/' do
      @commits = []
      OCTOKIT_CLIENT.commits(ENV['REPO'], 'master').each { |c| @commits << [c] }

      @commits.each do |commit|
        if commit[0].commit.message.include?('ci skip') || commit[0].commit.message.include?('skip ci')
          commit << 'n/a'
        else
          commit << OCTOKIT_CLIENT.status(ENV['REPO'], commit[0].sha)[:state]
        end
      end

      erb :index
    end
  end
end
