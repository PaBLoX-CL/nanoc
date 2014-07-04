# encoding: utf-8
require 'lib/nanoc/extra/deployers/git.rb'

class Nanoc::Extra::Deployers::GitTest < Nanoc::TestCase

  def test_run_without_output_folder
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Try running
    error = assert_raises(RuntimeError) do
      git.run
    end

    # Check error message
    assert_equal 'output/ does not exist. Please build your site first.', error.message
  end

  def test_run_with_defaults_options
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      {})

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Create site
    FileUtils.mkdir_p('output')
    
    # Try running
    git.run

    commands = <<-EOS
git init
git config --get remote.origin.url
git checkout master
git add -A
git commit --allow-empty -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push origin master
EOS

    assert_match Regexp.new(commands.chomp), git.instance_eval { @shell_cmd_args.join("\n") }
  end

  def test_run_with_custom_options
    # Create deployer
    git = Nanoc::Extra::Deployers::Git.new(
      'output/',
      { :remote => 'github', :branch => 'gh-pages', :forced => true })

    # Mock run_shell_cmd
    def git.run_shell_cmd(args, opts = {})
      @shell_cmd_args = [] unless defined? @shell_cmd_args
      @shell_cmd_args << args.join(' ')
    end

    # Create site
    FileUtils.mkdir_p('output')
    
    # Try running
    git.run

    commands = <<-EOS
git init
git config --get remote.github.url
git checkout gh-pages
git add -A
git commit --allow-empty -am Automated commit at .+ by nanoc \\d+\\.\\d+\\.\\d+
git push -f github gh-pages
EOS

    assert_match Regexp.new(commands.chomp), git.instance_eval { @shell_cmd_args.join("\n") }
  end

end
