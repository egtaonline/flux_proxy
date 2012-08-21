require 'drb/drb'

flux_proxy = DRbObject.new_with_uri('druby://localhost:30000')

loop do
  if flux_proxy.closed?
  else
    puts flux_proxy.exec!("date")
  end
  sleep 59
end
