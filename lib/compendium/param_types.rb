require 'compendium/numeric_helper'
require 'delegate'

module Compendium
  class Param < ::SimpleDelegator
    include Compendium::NumericHelper

    def scalar?; false; end
    def boolean?; false; end
    def date?; false; end
    def dropdown?; false; end
    def radio?; false; end

    def ==(other)
      return true if (value == other rescue false)
      super
    end

    # Need to explicitly delegate nil? to the object, otherwise it's always false
    # This is because SimpleDelegator is a non-nil object, and it only forwards non-defined methods!
    def nil?
      __getobj__.nil?
    end

    def to_f
      Kernel.Float(__getobj__)
    end

    def to_i
      Kernel.Integer(__getobj__)
    end
  end

  class ParamWithChoices < Param
    def initialize(obj, choices)
      @choices = choices

      if @choices.respond_to?(:call)
        # If given a proc, defer determining values until later.
        index = obj
      else
        index = numeric?(obj) ? obj.to_i : @choices.index(obj)
        raise IndexError if (!obj.nil? && index.nil?) || index.to_i.abs > @choices.length - 1
      end

      super(index)
    end

    def value
      @choices[self]
    end
  end

  class ScalarParam < Param
    def initialize(obj, *)
      super obj
    end

    # A scalar param just keeps track of a value with no modifications
    def scalar?
      true
    end
  end

  class BooleanParam < Param
    def initialize(obj, *)
      # If given 0, 1, or a version thereof (ie. "0"), pass it along
      return super obj.to_i if numeric?(obj) && (0..1).cover?(obj.to_i)
      super !!obj ? 0 : 1
    end

    def boolean?
      true
    end

    def value
      [true, false][self]
    end

    # When negating a BooleanParam, use the value instead
    def !
      !value
    end
  end

  class DateParam < Param
    def initialize(obj, *)
      if obj.respond_to?(:to_date)
        obj = obj.to_date
      else
        obj = Date.parse(obj) rescue nil
      end

      super obj
    end

    def date?
      true
    end
  end

  class RadioParam < ParamWithChoices
    def radio?
      true
    end
  end

  class DropdownParam < ParamWithChoices
    def dropdown?
      true
    end
  end
end