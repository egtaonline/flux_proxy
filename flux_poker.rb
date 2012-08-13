require 'drb/drb'

flux_proxy = DRbObject.new_with_uri('druby://localhost:3000')

loop do
  if flux_proxy.closed?
  else
    count = flux_proxy.exec!("qstat -n1 | grep egta-").split("\n")
    puts "#{count} current jobs"
  end
  sleep 59
end
