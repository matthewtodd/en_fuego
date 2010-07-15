module EnFuego
  autoload :Application, 'en_fuego/application'
  autoload :Session,     'en_fuego/session'
  autoload :User,        'en_fuego/user'

  class << self
    def datadir(*args)
      File.join(File.expand_path('../../data/en_fuego', __FILE__), *args)
    end
  end
end
