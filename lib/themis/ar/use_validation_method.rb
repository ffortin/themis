module Themis
  module AR
    # It encapsulates # {AR::BaseExtension::InstanceMethods#use_validation use_validation}
    # method.
    # It makes a model and its nested associations use another validation.
    class UseValidationMethod
      # @param [ActiveRecord::Base] model instance of model
      # @param [Symbol, String] new_name name of new validation set
      def initialize(model, new_name)
        @model    = model
        @new_name = new_name.to_sym

        unless @model.has_themis_validation?(@new_name)
          raise ArgumentError.new("Unknown validation: `#{@new_name.inspect}` for #{model.class}")
        end

        @new_validation_set = @model.themis_validation_sets[@new_name]
      end

      # Affect model and its nested associations.
      # Make them use the new validation set by assigning `@themis_validation`
      # instance variable.
      def execute!
        # NOTE: It breaks encapsulation of ActiveRecord model.
        # We do it because we don't wanna public "themis_validation=" method.
        # -- sergey.potapov 2012-08-14
        @model.instance_variable_set("@themis_validation", @new_name)

        nested = @new_validation_set.nested || @model.class.themis_default_nested
        if nested
          association_names = Array.wrap(nested)
          affect_associations(association_names)
        end
      end


      # Make associations use new validation set.
      # @param [Array<Symbol>] association_names names of associations
      def affect_associations(association_names)
        association_names.each { |name| affect_association(name) }
      end
      private :affect_associations

      # Make an association use new validation set.
      # Affect associations that are already loaded.
      # @param [Symbol] association_name
      def affect_association(association_name)
        unless @model.class.reflect_on_association(association_name)
          raise("`#{association_name}` is not an association on #{@model.class}")
        end

        association = @model.association(association_name)
        return if (!association.loaded? && !@model.new_record?)

        target = association.target
        case target
        when Array, ActiveRecord::Associations::CollectionProxy
          target.each {|obj| obj.send(:use_validation, @new_name) }
        when ActiveRecord::Base
          target.send(:use_validation, @new_name)
        else
          # do nothing
        end
      end
      private :affect_association

    end  # class UseValidationMethod
  end  # module AR
end  # module Themis
