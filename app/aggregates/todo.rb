# frozen_string_literal: true



module EventSourceryTodoApp
  module Aggregates

    module Invariants
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def invariant(name, &block)
          (@invariants ||= {})[name] = block
        end
      end

      def enforce(condition)
        invariant = self.class.instance_variable_get(:@invariants)[condition]
        instance_eval(&invariant)
      end
    end

    class Todo
      include EventSourcery::AggregateRoot
      include Invariants

      # These apply methods are the hook that this aggregate uses to update
      # its internal state from events.

      apply TodoAdded do |event|
        # We track the ID when a todo is added so we can ensure the same todo isn't
        # added twice.
        #
        # We can save more attributes off the event in here as necessary.
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

      # Invariants
      invariant :not_added do
        raise UnprocessableEntity, "Todo #{id.inspect} already exists" if added?
      end

      invariant :added do
        raise UnprocessableEntity, "Todo #{id.inspect} does not exist" unless added?
      end

      invariant :not_completed do
        raise UnprocessableEntity, "Todo #{id.inspect} is complete" if completed
      end

      invariant :not_abandoned do
        raise UnprocessableEntity, "Todo #{id.inspect} is abandoned" if abandoned
      end

      def add(payload)
        enforce(:not_added)

        apply_event(TodoAdded,
          aggregate_id: id,
          body: payload,
        )
      end

      # The methods below are how this aggregate handles different commands.
      # Note how they raise new events to indicate the change in state.

      def amend(payload)
        enforce(:added)
        enforce(:not_completed)
        enforce(:not_abandoned)

        apply_event(TodoAmended,
          aggregate_id: id,
          body: payload,
        )
      end

      def complete(payload)
        raise UnprocessableEntity, "Todo #{id.inspect} does not exist" unless added?
        raise UnprocessableEntity, "Todo #{id.inspect} already complete" if completed
        raise UnprocessableEntity, "Todo #{id.inspect} already abandoned" if abandoned

        apply_event(TodoCompleted,
          aggregate_id: id,
          body: payload,
        )
      end

      def abandon(payload)
        enforce(:added)
        enforce(:not_completed)
        # raise UnprocessableEntity, "Todo #{id.inspect} already complete" if completed
        raise UnprocessableEntity, "Todo #{id.inspect} already abandoned" if abandoned

        apply_event(TodoAbandoned,
          aggregate_id: id,
          body: payload,
        )
      end

      private

      def added?
        @aggregate_id
      end

      attr_reader :completed, :abandoned
    end
  end
end
