require_relative "lib/willow_camp_cli/version"

Gem::Specification.new do |spec|
  spec.name = "willow_camp_cli"
  spec.version = WillowCampCLI::VERSION
  spec.authors = ["Cassia Scheffer"]
  spec.email = ["cassia@willow.camp"]

  spec.summary = "Command-line interface for managing blog posts on a Willow Camp "
  spec.description = "A command-line interface for managing blog posts on a Willow Camp, supporting operations like listing, creating, updating, and deleting posts."
  spec.homepage = "https://github.com/cassiascheffer/willow_camp_cli"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["source_code_uri"] = "https://github.com/cassiascheffer/willow_camp_cli"
  spec.metadata["changelog_uri"] = "https://github.com/cassiascheffer/willow_camp_cli/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = ["willow-camp"]
  spec.require_paths = ["lib"]

  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "fileutils", "~> 1.0"
  spec.add_dependency "reverse_markdown", "~> 2.1"
end
