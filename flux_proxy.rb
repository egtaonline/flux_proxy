require 'drb/drb'
require 'bundler/setup'
Bundler.require(:default)

class FluxProxy
  EMAIL_LIST=['bcassell@umich.edu']
  attr_accessor :login

  def initialize(login_var)
    @email_sent = false
    @login = login_var
    @logger = Logger.new('output.log', 5, 102400000)
    p2 = Thread.new do
      loop do
        @logger.info { @login.exec!("date") }
        sleep 59
      end
    end
  end

  def closed?
    @login.closed?
  end

  def exec!(cmd)
    begin
      @logger.info { "Called with #{cmd}" }
      return email_alert("Connection closed") if @login.closed?
      @login.exec!(cmd)
    rescue Exception => e
      email_alert(e.message)
    end
  end

  def download!(src, destination, options)
    begin
      @logger.info { "Asked to download #{src} to #{destination} with #{options}" }
      return email_alert("Connection closed") if @login.closed?
      @login.scp.download!(src, destination, options)
    rescue Exception => e
      email_alert(e.message)
    end
  end

  def upload!(src, destination, options)
    begin
      @logger.info { "Asked to upload #{src} to #{destination} with #{options}" }
      return email_alert("Connection closed") if @login.closed?
      @transfer.upload!(src, destination, options)
    rescue Exception => e
      email_alert(e.message)
    end
  end

  def email_alert(message)
    begin
      @logger.debug { "Email already sent: #{@email_sent}"}
      @logger.error { "Asked to send email alert." }
      if @email_sent
        "failure, email already sent."
      else
        @email_sent = true
        EMAIL_LIST.each do |email_address|
          @logger.info { "Sent email to #{email_address}"}
          email = Pony.mail({
            to: email_address,
            subject: 'SSH-Proxy failure',
            body: message,
            via: :smtp,
            via_options: {
              address: 'smtp.gmail.com',
              port: '587',
              enable_starttls_auto: true,
              user_name: 'egtaonline',
              password: ENV['GMAIL_PASSWORD'],
              authentication: :plain,
              domain: "localhost.localhost"
            }
          })
          @logger.info { "#{email}" }
        end
        "failure, email sent"
      end
    rescue Exception => e
      @logger.fatal { e.message }
      @email_sent = false
    end
  end
end

uniqname = ARGV.shift
login = Net::SSH.start('flux-login.engin.umich.edu', uniqname)

p1 = fork do
  DRb.start_service('druby://localhost:30000', FluxProxy.new(login))
  DRb.thread.join
end
Process.detach(p1)