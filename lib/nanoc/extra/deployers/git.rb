# encoding: utf-8

# Copyright (c) 2012 Tom Vaughan <thomas.david.vaughan@gmail.com>
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

    # @see Nanoc::Extra::Deployer#run
    # Code adapted from Middleman Deploy (https://github.com/tvaughan/middleman-deploy)
    def run
      # Get params
      remote = self.config[:remote] || 'origin'
      branch = self.config[:branch] || 'gh-pages'

      puts "Deploying via git to remote='#{remote}' and branch='#{branch}'"

      # Check if remote is not a git url
      unless remote =~ /\.git$/
        remote = IO.popen(['git', 'config', '--get', "remote.#{remote}.url"]) { |c| c.read }.chop
      end

      # If the remote name doesn't exist in the main repo
      if remote == ''
        STDERR.puts "Can't deploy! Please add a remote with the name '#{opts[:remote]}' to your repo."
        exit(1)
      end

      Dir.chdir(self.source_path) do
        if File.exists?('.git')
          # Check if the remote repo has changed
          if remote != `git config --get remote.origin.url`.chop
            `git remote rm origin`
            `git remote add origin #{remote}`
          end
        else
          `git init`
          `git remote add origin #{remote}`
        end

        # If there is a branch with that name, switch to it, otherwise create a new one and switch to it
        if `git branch`.split("\n").any? { |b| b =~ /^#{branch}$/i }
          `git checkout #{branch}`
        else
          `git checkout -b #{branch}`
        end

        `git add -A`
        `git commit --allow-empty -am 'Automated commit at #{Time.now.utc} by nanoc #{Nanoc::VERSION}'`
        `git push -f origin #{branch}`
      end 
    end
  end
end
