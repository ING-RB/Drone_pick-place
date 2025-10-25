
classdef (Abstract) WidgetBehavior_Compact < handle
    % Mixin class inherited by Slider

    % Copyright 2020 The MathWorks, Inc.

    % ----------------------------------------------------------------------------
    properties (Dependent, Access = public, Hidden)
        % Property "Compact":
        %
        %   Reduces height of the Slider to accommodate upto
        %   three sliders in a single column.
        %   It is a logical and the default value is false.
        %
        %   Example:
        %       slider = matlab.ui.internal.toolstrip.Slider()
        %       slider.Compact = true;
        Compact
    end

    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        CompactPrivate = false;
    end

    % ----------------------------------------------------------------------------
    methods (Abstract, Access = protected)

        setPeerProperty(this)

    end

    % Public methods
    methods

        %% Public API: Get/Set
        % ShowText
        function value = get.Compact(this)
            % GET function
            value = this.CompactPrivate;
        end
        function set.Compact(this, value)
            % SET function
            this.CompactPrivate = value;
            this.setPeerProperty('compact',value);
        end
    end

    methods (Access = protected)

        function [mcos, peer] = getWidgetPropertyNames_Compact(this)
            mcos = {'CompactPrivate'};
            peer = {'compact'};
        end
    end
end

