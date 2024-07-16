# frozen_string_literal: true

module EventSourceryTodoApp
  module Aggregates
    module Invariants
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def invariant(name, default_message = "Invariant violation", &block)
          (@invariants ||= {})[name] = {block: block, message: default_message}
        end
      end

      def enforce(condition, message = nil, error = UnprocessableEntity)
        invariant = self.class.instance_variable_get(:@invariants)[condition]
        raise ArgumentError, "Invariant not defined: #{condition}" unless invariant

        custom_message = message || invariant[:message]
        begin
          instance_eval(&invariant[:block])
        rescue => e
          raise error, custom_message
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

      invariant :not_added, "Todo already exists" do
        raise default_error unless @aggregate_id.nil?
      end

      invariant :added, "Todo does not exist" do
        raise default_error if @aggregate_id.nil?
      end

      invariant :not_completed, "Todo is already complete" do
        raise default_error if @completed
      end

      invariant :not_abandoned, "Todo is already abandoned" do
        raise default_error if @abandoned
      end

      def add(payload)
        enforce(:not_added, "Todo #{id.inspect} already exists")

        apply_event(TodoAdded,
          aggregate_id: id,
          body: payload)
      end

      def amend(payload)
        enforce(:added, "Todo #{id.inspect} does not exist")
        enforce(:not_completed, "Todo #{id.inspect} is complete")
        enforce(:not_abandoned, "Todo #{id.inspect} is abandoned")

        apply_event(TodoAmended,
          aggregate_id: id,
          body: payload)
      end

      def complete(payload)
        enforce(:added, "Todo #{id.inspect} does not exist")
        enforce(:not_completed, "Todo #{id.inspect} already complete")
        enforce(:not_abandoned, "Todo #{id.inspect} already abandoned")

        apply_event(TodoCompleted,
          aggregate_id: id,
          body: payload)
      end

      def abandon(payload)
        enforce(:added, "Todo #{id.inspect} does not exist")
        enforce(:not_completed, "Todo #{id.inspect} already complete")
        enforce(:not_abandoned, "Todo #{id.inspect} already abandoned")

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
