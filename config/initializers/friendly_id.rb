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
  config.reserved_words = ReservedWords::RESERVED_WORDS
end
