# -*- coding: utf-8 -*-
require "spec_helper"

describe "Store-and-forward routing" do

  #
  # Environment
  #

  include AMQP::Spec
  include AMQP::SpecHelper

  em_before { AMQP.cleanup_state }
  em_after  { AMQP.cleanup_state }

  default_options AMQP_OPTS
  default_timeout 10

  amqp_before do
    @channel   = AMQP::Channel.new
    @channel.should be_open
  end

  after(:all) do
    AMQP.cleanup_state
    done
  end


  #
  # Examples
  #

  context "that uses fanout exchange" do
    context "with a single bound queue" do
      amqp_before do
        @exchange = @channel.fanout("amqpgem.integration.snf.fanout", :auto_delete => true)
        @queue    = @channel.queue("amqpgem.integration.snf.queue1",  :auto_delete => true)

        @queue.bind(@exchange)
      end

      it "allows asynchronous subscription to messages WITHOUT acknowledgements" do
        number_of_received_messages = 0
        # put a little pressure
        expected_number_of_messages = 300
        # It is always a good idea to use non-ASCII charachters in
        # various test suites. MK.
        dispatched_data             = "libertà è participazione (inviato a #{Time.now.to_i})"

        @queue.subscribe(:ack => false) do |payload|
          number_of_received_messages += 1
          if RUBY_VERSION =~ /^1.9/
            payload.force_encoding("UTF-8").should == dispatched_data
          else
            payload.should == dispatched_data
          end
        end # subscribe

        expected_number_of_messages.times do
          @exchange.publish(dispatched_data)
        end

        # 6 seconds are for Rubinius, it is surprisingly slow on this workload
        done(4.0) {
          number_of_received_messages.should == expected_number_of_messages
          @queue.unsubscribe
        }
      end # it


      it "allows asynchronous subscription to messages WITH acknowledgements" do
        number_of_received_messages = 0
        expected_number_of_messages = 500

        @queue.subscribe(:ack => true) do |payload|
          number_of_received_messages += 1
        end # subscribe

        expected_number_of_messages.times do
          @exchange.publish(rand)
        end

        # 6 seconds are for Rubinius, it is surprisingly slow on this workload
        done(3.0) {
          number_of_received_messages.should == expected_number_of_messages
          @queue.unsubscribe
        }
      end # it



      it "allows synchronous fetching of messages" do
        number_of_received_messages = 0
        expected_number_of_messages = 300

        dispatched_data             = "fetch me synchronously"

        expected_number_of_messages.times do
          @exchange.publish(dispatched_data)
        end

        expected_number_of_messages.times do
          @queue.pop do |payload|
            number_of_received_messages += 1

            if RUBY_VERSION =~ /^1.9/
              payload.force_encoding("UTF-8").should == dispatched_data
            else
              payload.should == dispatched_data
            end
          end # pop
        end # do

        done(0.5) {
          number_of_received_messages.should == expected_number_of_messages
        }
      end # it
    end # context
  end # context
end # describe
