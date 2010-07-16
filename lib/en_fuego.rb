module EnFuego
  autoload :Application, 'en_fuego/application'
  autoload :Extensions,  'en_fuego/extensions'
  autoload :User,        'en_fuego/user'

  class << self
    def datadir(*args)
      File.join(File.expand_path('../../data/en_fuego', __FILE__), *args)
    end
  end
end
