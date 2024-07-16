# frozen_string_literal: true

require "lib/invariants"

module EventSourceryTodoApp
  module Aggregates
    class Todo
      include EventSourcery::AggregateRoot
      include Invariants

      configure_invariants do |config|
        config.default_error = UnprocessableEntity
        config.default_invariant_message = "Todo invariant cannot be enforced: %{condition}"
      end

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
        enforce_invariants(:not_added)

        apply_event(TodoAdded,
                    aggregate_id: id,
                    body: payload)
      end

      def amend(payload)
        enforce_invariants(
          :added,
          :not_completed,
          :not_abandoned
        ) do
          {
            not_completed: { msg: "Todo #{id.inspect} is complete" },
            not_abandoned: { msg: "Todo #{id.inspect} is abandoned" }
          }
        end

        apply_event(TodoAmended,
                    aggregate_id: id,
                    body: payload)
      end

      def complete(payload)
        enforce_invariants(
          :added,
          :not_completed,
          :not_abandoned
        )

        apply_event(TodoCompleted,
                    aggregate_id: id,
                    body: payload)
      end

      def abandon(payload)
        enforce_invariants(
          :added,
          :not_completed,
          :not_abandoned
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
