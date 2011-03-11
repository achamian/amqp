require 'spec_helper'
require 'amqp'

describe AMQP, 'class object' do

  #
  # Environment
  #

  subject { AMQP }

  #
  # Examples
  #

  its(:settings) do
    should == {
      :host    => "127.0.0.1",
      :port    => 5672,
      :user    => "guest",
      :pass    => "guest",
      :vhost   => "/",
      :timeout => nil,
      :logging => false,
      :ssl     => false
    }
  end

  its(:client) { should == AMQP::BasicClient }




  describe 'logging' do
    after(:all) do
      AMQP.logging = false
    end

    it 'is silent by default' do
      AMQP.logging.should be_false
    end
  end # .logging=




  describe '.start' do

    #
    # Environment
    #

    include AMQP::SpecHelper

    em_before { AMQP.cleanup_state }
    em_after  { AMQP.cleanup_state }

    #
    # Examples
    #

    it 'yields to given block AFTER connection is established' do
      em do
        AMQP.start AMQP_OPTS do
          @block_fired = true

          AMQP.connection.should be_connected
        end
        done(0.1) { @block_fired.should be_true }
      end
    end
  end # .start




  describe '.stop' do
    context "when connection is not established" do
      it 'is a no-op' do
        expect { @res = AMQP.stop }.to_not raise_error
        @res.should be_nil
      end # it
    end # context


    context 'with established AMQP connection' do

      #
      #
      #

      include AMQP::Spec
      after           { AMQP.cleanup_state; done }
      default_options AMQP_OPTS

      #
      # Examples
      #

      it 'unsets active AMQP broker connection. Mind the delay!' do
        AMQP.start(AMQP_OPTS)
        AMQP.connection.should be_connected

        AMQP.stop
        AMQP.connection.should_not be_nil
        done(0.1) { AMQP.connection.should be_nil }
      end # it

      it 'yields to given block AFTER disconnect (BUT before AMQP.conn is cleared!)' do
        AMQP.stop do
          @block_fired = true
          AMQP.connection.should_not be_nil
          AMQP.instance_variable_get(:@closing).should be_true
        end
        done(0.1) { @block_fired.should be_true }
      end # it
    end # context
  end # describe
end # describe AMQP
