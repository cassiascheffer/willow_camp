class ScoutApmLogFormatter < SemanticLogger::Formatters::Json
  def call(log, logger)
    # Just use the default JSON formatter
    super
  end
end
