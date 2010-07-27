module EnFuego
  autoload :Application, 'en_fuego/application'
  autoload :Comments,    'en_fuego/comments'
  autoload :Distance,    'en_fuego/distance'
  autoload :Duration,    'en_fuego/duration'
  autoload :Entry,       'en_fuego/entry'
  autoload :Extensions,  'en_fuego/extensions'
  autoload :Message,     'en_fuego/message'
  autoload :User,        'en_fuego/user'
  autoload :Workout,     'en_fuego/workout'

  class << self
    def datadir(*args)
      File.join(File.expand_path('../../data/en_fuego', __FILE__), *args)
    end
  end
end
