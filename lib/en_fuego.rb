module EnFuego
  autoload :Application,    'en_fuego/application'
  autoload :Authentication, 'en_fuego/authentication'
  autoload :User,           'en_fuego/user'

  class << self
    def datadir(*args)
      File.join(File.expand_path('../../data/en_fuego', __FILE__), *args)
    end
  end
end
