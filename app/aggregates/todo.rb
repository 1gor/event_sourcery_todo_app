# frozen_string_literal: true

module EventSourceryTodoApp
  module Aggregates
    module Invariants
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def invariant(name, &block)
          (@invariants ||= {})[name] = { block: block }
        end
      end

      def enforce(condition, message = nil, error = UnprocessableEntity)
        invariant = self.class.instance_variable_get(:@invariants)[condition]
        raise ArgumentError, "Invariant not defined: #{condition}" unless invariant

        custom_message = message
        begin
          instance_exec(custom_message, error, &invariant[:block])
        rescue => e
          raise error, custom_message || e.message
        end
      end

      def enforce_invariants(conditions = {})
        conditions.each do |condition, options|
          if options.is_a?(Hash)
            message = options[:msg]
            error = options[:e] || UnprocessableEntity
            enforce(condition, message, error)
          else
            enforce(condition)
          end
        end
      end
    end

    class Todo
      include EventSourcery::AggregateRoot
      include Invariants

      apply TodoAdded do |event|
        @aggregate_id = event.aggregate_id
      end

      apply TodoAmended do |event|
      end

      apply TodoCompleted do |event|
        @completed = true
      end

      apply TodoAbandoned do |event|
        @abandoned = true
      end

      apply StakeholderNotifiedOfTodoCompletion do |event|
      end

      invariant :not_added do |message, error|
        raise error, message || "Todo #{id.inspect} already exists" unless @aggregate_id.nil?
      end

      invariant :added do |message, error|
        raise error, message || "Todo #{id.inspect} does not exist" if @aggregate_id.nil?
      end

      invariant :not_completed do |message, error|
        raise error, message || "Todo #{id.inspect} already complete" if @completed
      end

      invariant :not_abandoned do |message, error|
        raise error, message || "Todo #{id.inspect} already abandoned" if @abandoned
      end

      def add(payload)
        enforce_invariants(not_added: nil)

        apply_event(TodoAdded,
                    aggregate_id: id,
                    body: payload)
      end

      def amend(payload)
        enforce_invariants(
          added: nil,
          not_completed: {msg: "Todo #{id.inspect} is complete"},
          not_abandoned: {msg: "Todo #{id.inspect} is abandoned"}
        )

        apply_event(TodoAmended,
                    aggregate_id: id,
                    body: payload)
      end

      def complete(payload)
        enforce_invariants(
          added: nil,
          not_completed: nil,
          not_abandoned: nil
        )

        apply_event(TodoCompleted,
                    aggregate_id: id,
                    body: payload)
      end

      def abandon(payload)
        enforce_invariants(
          added: nil,
          not_completed: nil,
          not_abandoned: nil
        )

        apply_event(TodoAbandoned,
                    aggregate_id: id,
                    body: payload)
      end

      private

      def added?
        @aggregate_id
      end

      attr_reader :completed, :abandoned
    end
  end
end
