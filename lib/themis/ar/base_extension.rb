module Themis
  module AR
    # Extends ActiveRecord::Base to make it support has_validation and use_validation
    # methods.
    # It adds some class attributes to model:
    # * themis_validation - name of validation, symbol or nil
    # * themis_validation_sets - hash where key is symbol(validation name) and value is {ValidationSet}.
    # * themis_default_validation - name of default validation.
    module BaseExtension
      extend ActiveSupport::Autoload

      # :nodoc:
      def self.included(base)
        base.extend         ClassMethods
        base.send :include, InstanceMethods

        base.class_eval(<<-eoruby, __FILE__, __LINE__+1)
          attr_reader :themis_validation

          class_attribute :themis_validation_sets
          class_attribute :themis_default_validation

          delegate :has_themis_validation?, :to => "self.class"
        eoruby
      end

      # :nodoc:
      module ClassMethods
        # @overload has_validation(name, options, &block)
        #   Declare validation set using block
        #   @example
        #     has_validation :soft, :nested => :account, :default => true do |validation|
        #       validation.validates_presence_of :some_date
        #     end
        #   @param [Symbol] name name of validation set
        #   @param [Hash] options options: :default, :nested
        #   @param [Proc] block proc which receives {ModelProxy} and defines validators
        #   @option options [Boolean] :default make it validation be used by default
        #   @option options [Symbol, Array<Symbol>] :nested association which should be affected when validation {#use_validation} is called
        #
        # @overload has_validation(name, validation_module, options, &block)
        #   Declare validation set on model using {Themis::Validation validation module} or(and) block.
        #   @example
        #     has_validation :soft, SoftValidation, :default => true
        #   @param [Symbol] name name of validation set
        #   @param [Module] validation_module module extended by {Themis::Validation}.
        #   @param [Hash] options options: :default, :nested
        #   @param [Proc] block proc which receives {ModelProxy} and defines validators
        #   @option options [Boolean] :default make it validation be used by default
        #   @option options [Symbol, Array<Symbol>] :nested association which should be affect when validation {#use_validation} is called
        def has_validation(name, *validation_module_and_options, &block)
          options           = validation_module_and_options.extract_options!
          validation_module = validation_module_and_options.first
          Themis::AR::HasValidationMethod.new(self, name, validation_module, options, block).execute!
        end

        # Verify that model has {ValidationSet validation set} with passed name.
        # @param [Symbol] name name of validation set
        def has_themis_validation?(name)
          themis_validation_sets.keys.include?(name.to_sym)
        end
      end  # module ClassMethods

      # :nodoc:
      module InstanceMethods
        # Switch validation.
        # @param [Symbol] validation_name name of {ValidationSet validation set}
        def use_validation(validation_name)
          Themis::AR::UseValidationMethod.new(self, validation_name).execute!
        end

        # Do not use any of {ValidationSet validation sets}.
        def use_no_validation
          @themis_validation = nil
        end
      end  # module InstanceMethods

    end  # module BaseExtension
  end  # module AR
end  # module Themis