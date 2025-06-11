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
  config.routes = :friendly
  config.use :finders
  config.use :reserved
  config.treat_reserved_as_conflict = true
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
    confirmation
    dashboard
    demo
    dev
    development
    dmarc
    dns
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
    register
    registration
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
    unlock
    user
    users
    verify
    webmail
    www
  ]
end
