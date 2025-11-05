# frozen_string_literal: true

# Pagy initializer file (43.0.0)
# Customize only what you really need and notice that the core Pagy works also without any of the following lines.

# Pagy Options
# See https://ddnexus.github.io/pagy/docs/api/pagy#options
# You can set any pagy option as a Pagy.options. They can also be overridden per instance by just passing them to
# Pagy.new|pagy(:offset, ...)|pagy(:countless, ...)|pagy(:calendar, ...) or any of the #pagy* controller methods
# Here are the few that make more sense as defaults:
Pagy.options[:limit] = 50
Pagy.options[:slots] = 7
Pagy.options[:compact] = false
Pagy.options[:page_key] = "page"
Pagy.options[:max_pages] = 3000

# Note: All extras have been integrated into core in version 43.x
# Features like countless, calendar, and search are now available via:
# pagy(:countless, ...), pagy(:calendar, ...), pagy(:offset, ...)
# No extra requires needed!

# I18n
# Pagy internal I18n: ~18x faster using ~10x less memory than the i18n gem
# See https://ddnexus.github.io/pagy/docs/api/i18n
# Notice: No need to configure anything in this section if your app uses only "en"
#
# Examples:
# load the "de" built-in locale:
# Pagy::I18n.load(locale: 'de')
#
# load the "de" locale defined in the custom file at :filepath:
# Pagy::I18n.load(locale: 'de', filepath: 'path/to/pagy-de.yml')

# When you are done setting your own options, freeze them so they won't get changed accidentally
Pagy.options.freeze
