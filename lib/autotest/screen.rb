require 'rubygems'
require 'autotest'

##
# Autotest::Screen shows autotest/autospec progress on GNU Screen's status line.
#
# == FEATURES:
# * Screenshots are available in here[http://f.hatena.ne.jp/yoshuki/autotest_screen/].
#
# == SYNOPSIS
# $HOME/.autotest
#   require 'autotest/screen'
#   # Autotest::Screen.statusline = '%H %`%-w%{=b bw}%n %t%{-}%+w (your statusline)'
#

class Autotest::Screen
  VERSION = '4.0.1'

  DEFAULT_STATUSLINE = '%99`%{= kw} %100`%112`%= %102`%101`%114`%115`%108`%113`%119`%117`%118`%116`%106`%104`%103`%105`%107`%Y-%m-%d %0c:%s'
  DEFAULT_SCREEN_CMD = 'screen'

  SCREEN_COLOR = {
    :black  => 'dd',
    :green  => 'gw',
    :yellow => 'yk',
    :red    => 'rw'
  }

  def self.message(msg, color = :black)
    col = SCREEN_COLOR[color]
    msg = %Q[ %{=b #{col}} #{msg} %{-}]
    send_cmd(msg)
  end

  def self.clear
    send_cmd('')
  end

  def self.run_screen_session?
    str = `#{screen_cmd} -ls`
    str.match(/(\d+) Socket/) && ($1.to_i > 0)
  end

  def self.execute?
    !($TESTING || !run_screen_session?)
  end

  @statusline, @screen_cmd = nil
  def self.statusline; @statusline || DEFAULT_STATUSLINE.dup; end
  def self.statusline=(a); @statusline = a; end
  def self.screen_cmd; @screen_cmd || DEFAULT_SCREEN_CMD.dup; end
  def self.screen_cmd=(a); @screen_cmd = a; end

  def self.send_cmd(msg)
    cmd = %(#{screen_cmd} -X eval 'hardstatus alwayslastline "#{(msg + statusline).gsub('"', '\"')}"') #' stupid ruby-mode
    system cmd
    nil
  end

  @last_message = {}

  # All blocks return false, to execute each of following blocks defined in user's own ".autotest".

  # Do nothing.
  #Autotest.add_hook :all_good do |at|
  #  next false
  #end

  Autotest.add_hook :died do |at|
    message "Exception occured. (#{at.class})", :red
    next false
  end

  # Do nothing.
  #Autotest.add_hook :green do |at|
  #  next false
  #end

  Autotest.add_hook :initialize do |at|
    message "Run with #{at.class}" if execute?
    next false
  end

  # Do nothing.
  #Autotest.add_hook :interrupt do |at|
  #  next false
  #end

  Autotest.add_hook :quit do |at|
    clear if execute?
    next false
  end

  Autotest.add_hook :ran_command do |at|
    next false unless execute?
    next false if at.results.empty?
    
    results = at.results.join
    failures_count = results.scan(at.failed_results_re).length

    if failures_count > 0
      @last_message = {:message => "Red F:#{failures_count}", :color => :red}
    else
      @last_message = {:message => 'All Green', :color => :green}
    end
    next false
  end

  # Do nothing.
  #Autotest.add_hook :red do |at|
  #  next false
  #end

  # Do nothing.
  #Autotest.add_hook :reset do |at|
  #  next false
  #end

  Autotest.add_hook :run_command do |at|
    message 'Running' if execute?
    next false
  end

  # Do nothing.
  #Autotest.add_hook :updated do |at, updated|
  #  next false
  #end

  Autotest.add_hook :waiting do |at|
    message @last_message[:message], @last_message[:color] if execute?
    next false
  end
end
