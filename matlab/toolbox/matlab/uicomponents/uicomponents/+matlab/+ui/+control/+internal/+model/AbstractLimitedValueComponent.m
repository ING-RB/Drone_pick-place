classdef (Hidden) AbstractLimitedValueComponent < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.LimitsComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer

    properties(NonCopyable, Dependent, AbortSet)
        ValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];

        ValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        ValueChanged

        ValueChanging
    end

    properties(NonCopyable, Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];

        PrivateValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = AbstractLimitedValueComponent(varargin)

            obj.attachCallbackToEvent('ValueChanged', 'PrivateValueChangedFcn');
            obj.attachCallbackToEvent('ValueChanging', 'PrivateValueChangingFcn');

        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods

        function set.ValueChangedFcn(obj, newValueChangedFcn)
            % Property Setting
            obj.PrivateValueChangedFcn = newValueChangedFcn;
            obj.markPropertiesDirty({'ValueChangedFcn'});
        end

        function value = get.ValueChangedFcn(obj)
            value = obj.PrivateValueChangedFcn;
        end

        function set.ValueChangingFcn(obj, newValueChangingFcn)
            % Property Setting
            obj.PrivateValueChangingFcn = newValueChangingFcn;
            obj.markPropertiesDirty({'ValueChangingFcn'});
        end

        function value = get.ValueChangingFcn(obj)
            value = obj.PrivateValueChangingFcn;
        end


    end
end
