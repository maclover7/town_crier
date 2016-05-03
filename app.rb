module TownCrier
  class Application < ::Sinatra::Application
    get '/' do
      'hello'
    end
  end
end
