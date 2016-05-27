class ACOS < Oxidized::Model
  # A10 ACOS model for AX and Thunder series

  comment  '! '

  ##ACOS prompt changes depending on the state of the device
  prompt /^([-\w.\/:?\[\]\(\)]+[#>]\s?)$/

  cmd 'show version' do |cfg|
    cfg.gsub! /\s(Last configuration saved at).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Memory).*/, ' \\1 <removed>'
    cfg.gsub! /\s(Current time is).*/, ' \\1 <removed>'
    cfg.gsub! /\s(The system has been up).*/, ' \\1 <removed>'
    comment cfg
  end

  cmd 'show bootimage' do |cfg|
    comment cfg
  end

  cmd 'show license' do |cfg|
    comment cfg
  end

  cmd 'show running-config all-partitions' do |cfg|
     cfg.gsub! /(Current configuration).*/, '\\1 <removed>'
     cfg.gsub! /(Configuration last updated at).*/, '\\1 <removed>'
     cfg.gsub! /(Configuration last saved at).*/, '\\1 <removed>'
     cfg.gsub! /(Configuration last synchronized at).*/, '\\1 <removed>'
  end

  cmd 'show aflex all-partitions' do |cfg|
    comment cfg
  end

  cmd 'show aflex all-partitions' do |cfg|
    @partitions_aflex = cfg.lines.each_with_object({}) do |l,h|
      h[$1] = [] if l.match /partition: (.+)/
      # only consider scripts that have passed syntax check
      h[h.keys.last] << $1 if l.match /^([\w-]+) +Check/
    end
    ''
  end

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.each_line.to_a[1..-2].join
  end

  pre do
    unless @partitions_aflex.empty?
      out = []
      @partitions_aflex.each do |partition,arules|
        out << "! partition: #{partition}"
        arules.each do |name|
          cmd("show aflex #{name} partition #{partition}") do |cfg|
            content = cfg.split(/Content:/).last.strip
            out << "aflex create #{name}"
            out << content
            out << ".\n"
          end
        end
      end
      out.join "\n"
    end
  end

  cfg :telnet do
    username  /login:/
    password  /^Password:/
  end
  
  cfg :telnet, :ssh do
    # preferred way to handle additional passwords
    post_login do
      pw = vars(:enable)
      pw ||= ""
      send "enable\r\n"
      cmd pw
    end
    post_login 'terminal length 0'
    post_login 'terminal width 0'
    pre_logout "exit\nexit\nY\r\n"
  end

end
