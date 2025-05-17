# FriendlyId Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `friendly_id` class method or defining
# methods in your model.
#
# To learn more, check out the guide:
#
# http://norman.github.io/friendly_id/file.Guide.html

FriendlyId.defaults do |config|
  config.use :reserved

  config.reserved_words = %w[
    _dmarc
    _spf
    account
    accounts
    admin
    administrator
    api
    app
    assets
    autodiscover
    beta
    billing
    blog
    com
    dashboard
    demo
    dev
    development
    dns
    dmarc
    edit
    edu
    ftp
    gov
    help
    host
    images
    imap
    index
    javascripts
    local
    localhost
    login
    logout
    mail
    mil
    moderator
    mx
    net
    new
    news
    ns1
    ns2
    ns3
    ns4
    org
    owner
    pop
    portal
    post
    posts
    root
    secure
    server
    session
    sessions
    smtp
    ssh
    staging
    static
    status
    stylesheets
    support
    sysadmin
    system
    test
    user
    users
    webmail
    www
  ]

  config.treat_reserved_as_conflict = true
  config.use :finders
  config.slug_limit = 255
  config.sequence_separator = "-"

  #  ## Tips and Tricks
  #
  #  ### Controlling when slugs are generated
  #
  # As of FriendlyId 5.0, new slugs are generated only when the slug field is
  # nil, but if you're using a column as your base method can change this
  # behavior by overriding the `should_generate_new_friendly_id?` method that
  # FriendlyId adds to your model. The change below makes FriendlyId 5.0 behave
  # more like 4.0.
  # Note: Use(include) Slugged module in the config if using the anonymous module.
  # If you have `friendly_id :name, use: slugged` in the model, Slugged module
  # is included after the anonymous module defined in the initializer, so it
  # overrides the `should_generate_new_friendly_id?` method from the anonymous module.
  #
  # config.use :slugged
  # config.use Module.new {
  #   def should_generate_new_friendly_id?
  #     slug.blank? || <your_column_name_here>_changed?
  #   end
  # }
  #
  # FriendlyId uses Rails's `parameterize` method to generate slugs, but for
  # languages that don't use the Roman alphabet, that's not usually sufficient.
  # Here we use the Babosa library to transliterate Russian Cyrillic slugs to
  # ASCII. If you use this, don't forget to add "babosa" to your Gemfile.
  #
  # config.use Module.new {
  #   def normalize_friendly_id(text)
  #     text.to_slug.normalize! :transliterations => [:russian, :latin]
  #   end
  # }
end
