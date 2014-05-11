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
  #       forced:     true
  #
  class Git < ::Nanoc::Extra::Deployer
    identifier :git

    # @see Nanoc::Extra::Deployer#run
    # Code adapted from Middleman Deploy (https://github.com/tvaughan/middleman-deploy)
    def run
      unless File.exists?(self.source_path)
        raise "#{self.source_path} does not exist. Please run 'nanoc compile' first."
      end

      remote = config.fetch(:remote, 'origin')
      branch = config.fetch(:branch, 'master')
      forced = config.fetch(:forced, false)

      puts "Deploying via git to remote='#{remote}' and branch='#{branch}'"

      Dir.chdir(self.source_path) do
        if not File.exists?('.git')
          puts "#{self.source_path} does not appear to be a Git repo. Creating one..."
          run_shell_cmd(%w( git init ))
        end

        # If the remote is not a URL already, get it from git config
        unless remote.match(/:\/\//)
          remote = get_output_from_cmd(
            %W( git config --get remote.#{remote}.url ),
            "Please add a remote called '#{remote}' to the repo inside #{self.source_path}."
          )
        end

        # If the branch exists then switch to it, otherwise prompt the user to create one.
        begin
          run_shell_cmd(%W( git checkout #{branch} ))
        rescue
          raise "Branch '#{branch}' does not exist inside #{self.source_path}. Please create one and try again."
        end

        msg = "Automated commit at #{Time.now.utc} by nanoc #{Nanoc::VERSION}"
        run_shell_cmd(%w( git add -A ))
        run_shell_cmd(%W( git commit --allow-empty -am #{msg} ))
        if forced
          puts 'Warning: forced update'
          run_shell_cmd(%W( git push #{forced} #{remote} #{branch} ))
        else
          run_shell_cmd(%W( git push #{remote} #{branch} ))
        end
      end 
    end

  private

    def run_shell_cmd(cmd)
      piper = Nanoc::Extra::Piper.new(:stdout => $stdout, :stderr => $stderr)
      piper.run(cmd, nil)
    end

    def get_output_from_cmd(cmd, errmsg = 'An unexpected error has occurred')
      stdout = StringIO.new
      piper = Nanoc::Extra::Piper.new(:stdout => stdout, :stderr => $stderr)
      begin
        piper.run(cmd, nil)
      rescue Nanoc::Extra::Piper::Error
        raise errmsg
      end
      stdout.string.chop
    end

  end
end
