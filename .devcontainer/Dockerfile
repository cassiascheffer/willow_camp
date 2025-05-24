# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.4
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

USER root

# Specify the Node.js version
ARG NODE_VERSION=23

# Install Node.js using sudo
RUN sudo apt-get update \
 && sudo apt-get install -y curl gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash - \
 && sudo apt-get install -y nodejs \
 && sudo apt-get clean \
 && sudo rm -rf /var/lib/apt/lists/*

# Install Yarn globally as root
RUN npm install -g yarn

# Switch back to non-root user (usually 'vscode' in DevContainers)
USER vscode