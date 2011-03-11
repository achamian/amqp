# encoding: utf-8

$:.unshift(File.expand_path("../../lib", __FILE__))
require 'amqp'

# For ack to work appropriately you must shutdown AMQP gracefully,
# otherwise all items in your queue will be returned
Signal.trap('INT') { AMQP.stop { EM.stop } }
Signal.trap('TERM') { AMQP.stop { EM.stop } }

AMQP.start(:host => 'localhost') do
  AMQP::Channel.queue('awesome').publish('Totally rad 1')
  AMQP::Channel.queue('awesome').publish('Totally rad 2')
  AMQP::Channel.queue('awesome').publish('Totally rad 3')

  i = 0

  # Stopping after the second item was acked will keep the 3rd item in the queue
  AMQP::Channel.queue('awesome').subscribe(:ack => true) do |h, m|
    if (i += 1) == 3
      puts 'Shutting down...'
      AMQP.stop { EM.stop }
    end

    if AMQP.closing?
      puts "#{m} (ignored, redelivered later)"
    else
      puts m
      h.ack
    end
  end
end

__END__

Totally rad 1
Totally rad 2
Shutting down...
Totally rad 3 (ignored, redelivered later)

When restarted:

Totally rad 3
Totally rad 1
Shutting down...
Totally rad 2 (ignored, redelivered later)
Totally rad 3 (ignored, redelivered later)
