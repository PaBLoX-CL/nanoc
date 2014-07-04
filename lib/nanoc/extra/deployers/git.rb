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
    def run
      unless File.exists?(self.source_path)
        raise "#{self.source_path} does not exist. Please run 'nanoc compile' first."
      end

      remote = config.fetch(:remote, 'origin')
      branch = config.fetch(:branch, 'master')
      forced = config.fetch(:forced, false)

      puts "Deploying via git to remote='#{remote}' and branch='#{branch}'"

      Dir.chdir(self.source_path) do
        unless File.exists?('.git')
          puts "#{self.source_path} does not appear to be a Git repo. Creating one..."
          run_shell_cmd(%w( git init ))
        end

        # If the remote is not a URL already, get it from git config
        unless remote.match(/:\/\//)
          stdout = StringIO.new
          begin
            run_shell_cmd(%W( git config --get remote.#{remote}.url ), :stdout => stdout)
          rescue Nanoc::Extra::Piper::Error
            raise "Please add a remote called '#{remote}' to the repo inside #{self.source_path}."
          end
          remote = stdout.string.chop
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
          run_shell_cmd(%W( git push -f #{remote} #{branch} ))
        else
          run_shell_cmd(%W( git push #{remote} #{branch} ))
        end
      end 
    end

  private

    def run_shell_cmd(cmd, opts = {})
      stdout = opts.fetch(:stdout, $stdout)
      piper = Nanoc::Extra::Piper.new(:stdout => stdout, :stderr => $stderr)
      piper.run(cmd, nil)
    end

  end
end
