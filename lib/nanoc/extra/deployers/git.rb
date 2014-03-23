# encoding: utf-8

module Nanoc::Extra::Deployers

  # A deployer that deploys a site using [Git](http://git-scm.com).
  #
  # @example A deployment configuration for GitHub Pages:
  #
  #   deploy:
  #     default:
  #       kind:       git
  #       remote:     git@github.com:myself/myproject.git
  #       branch:     gh-pages
  #
  class Git < ::Nanoc::Extra::Deployer
    identifier :git

    # @see Nanoc::Extra::Deployer#run
    # Code adapted from Middleman Deploy (https://github.com/tvaughan/middleman-deploy)
    def run
      # Get params
      remote = self.config[:remote] || 'origin'
      branch = self.config[:branch] || 'gh-pages'
      output_dir = self.source_path

      puts "Deploying via git to remote=\"#{remote}\" and branch=\"#{branch}\""

      # Check if remote is not a git url
      unless remote =~ /\.git$/
        remote = `git config --get remote.#{remote}.url`.chop
      end

      # If the remote name doesn't exist in the main repo
      if remote == ''
        STDERR.puts "Can't deploy! Please add a remote with the name '#{opts[:remote]}' to your repo."
        exit(1)
      end

      Dir.chdir(output_dir) do
        unless File.exists?('.git')
          `git init`
          `git remote add origin #{remote}`
        else
          unless remote == `git config --get remote.origin.url`.chop
          # Check if the remote repo has changed
            `git remote rm origin`
            `git remote add origin #{remote}`
          end
        end

        if `git branch`.split("\n").any? { |b| b =~ /#{branch}/i }
        # If there is a branch with that name, switch to it, otherwise create a new one and switch to it
          `git checkout #{branch}`
        else
          `git checkout -b #{branch}`
        end

        `git add -A`
        # '"message"' double quotes to fix windows issue
        `git commit --allow-empty -am 'Automated commit at #{Time.now.utc} by nanoc #{Nanoc::VERSION}'`
        `git push -f origin #{branch}`
      end 
    end
  end
end
