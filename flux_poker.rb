require 'drb/drb'

flux_proxy = DRbObject.new_with_uri('druby://localhost:30000')

loop do
  if flux_proxy.closed?
  else
    out = flux_proxy.exec!("qstat -n1 | grep egta-")
    puts "#{ out ? out.split("\n").count : 0 } current job(s)"
  end
  sleep 59
end
