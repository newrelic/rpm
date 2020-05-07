# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent
  module InfiniteTracing
    class Client
      include Constants

      def << segment
        buffer << segment
      end

      # Transfers spans in streaming buffer from previous 
      # client (if any) and returns self (so we chain the call)
      def transfer previous_client
        return self unless previous_client
        previous_client.buffer.transfer buffer
        self
      end

      # provides the correct streaming buffer instance based on whether the
      # client is currently suspended.
      def new_streaming_buffer
        buffer_class = suspended? ? SuspendedStreamingBuffer : StreamingBuffer
        buffer_class.new Config.span_events_queue_size
      end

      def buffer
        @buffer ||= new_streaming_buffer
      end

      def flush
        buffer.flush_queue
      end

      def initialize
        start_streaming
      end

      # Literal codes are all mapped to unique class names, so we can deduce the 
      # name of the error to report in the metric from the error's class name.
      def grpc_error_metric_name error
        name = error.class.name.split(":")[-1].upcase
        GRPC_ERROR_NAME % name
      end

      # Reports AND logs general response metric along with a more specific error metric
      def record_error_metrics_and_log error
        NewRelic::Agent.record_metric RESPONSE_ERROR_METRIC, 0.0
        if error.is_a? GRPC::BadStatus
          NewRelic::Agent.record_metric grpc_error_metric_name(error), 0.0
        else
          NewRelic::Agent.record_metric GRPC_OTHER_ERROR, 0.0
        end
        NewRelic::Agent.logger.error "gRPC response error received.", error
      end

      def handle_error error
        puts "HANDLE ERROR: #{error.inspect}"
        record_error_metrics_and_log error

        case error
        when GRPC::Unavailable then restart
        when GRPC::Unimplemented then suspend
        else
          NewRelic::Agent.logger.error "Unhandled error in gRPC client!", error
          raise error
        end 
      end

      def suspended?
        @suspended ||= false
      end

      def suspend
        @suspended = true
        @buffer = new_streaming_buffer
      end

      def restart
        old_buffer = @buffer
        @buffer = new_streaming_buffer
        old_buffer.transfer @buffer
        start_streaming
      end

      def start_streaming
        return if suspended?
        @response_handler = record_spans
      end

      def record_spans
        return if suspended?
        RecordStatusHandler.new self, Connection.record_spans(self, buffer.enumerator)
      end

      def record_span_batches
        return if suspended?
        RecordStatusHandler.new self, Connection.record_span_batches(self, buffer.batch_enumerator)
      end

    end

  end
end
