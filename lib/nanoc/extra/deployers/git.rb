# encoding: utf-8

# Portions Copyright (c) 2012 Tom Vaughan <thomas.david.vaughan@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
      remote = config.fetch(:remote, 'origin')
      branch = config.fetch(:branch, 'gh-pages')

      puts "Deploying via git to remote='#{remote}' and branch='#{branch}'"

      # If the remote is not a URL already, get it from git config
      unless remote.match(/:\/\//)
        stdout = StringIO.new
        piper = Nanoc::Extra::Piper.new(:stdout => stdout, :stderr => $stderr)
        piper.run(%W( git config --get remote.#{remote}.url ), nil)
        remote = stdout.string.chop
      end

      raise "Please add a remote called '#{opts[:remote]}' to your repo." if remote == ''

      Dir.chdir(self.source_path) do
        if File.exists?('.git')
          # Check if the remote url has changed
          if remote != run_shell_cmd(%w( git config --get remote.origin.url )).chop
            run_shell_cmd(%w( git remote rm origin ))
            run_shell_cmd(%W( git remote add origin #{remote} ))
          end
        else
          run_shell_cmd(%w( git init ))
          run_shell_cmd(%W( git remote add origin #{remote} ))
        end

        # If the branch exists then switch to it, otherwise create a new one and switch to it
        if run_shell_cmd(%w( git branch )).split("\n").any? { |b| b =~ /^#{branch}$/i }
          run_shell_cmd(%W( git checkout #{branch} ))
        else
          run_shell_cmd(%W( git checkout -b #{branch} ))
        end

        msg = "Automated commit at #{Time.now.utc} by nanoc #{Nanoc::VERSION}"
        run_shell_cmd(%w( git add -A ))
        run_shell_cmd(%W( git commit --allow-empty -am #{msg} ))
        run_shell_cmd(%W( git push -f origin #{branch} ))
      end 
    end

  private

    def run_shell_cmd(cmd)
      piper = Nanoc::Extra::Piper.new(:stdout => $stdout, :stderr => $stderr)
      piper.run(cmd, nil)
    end

  end
end
