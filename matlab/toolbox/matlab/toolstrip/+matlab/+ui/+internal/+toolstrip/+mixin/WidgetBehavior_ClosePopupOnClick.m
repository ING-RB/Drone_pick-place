classdef (Abstract) WidgetBehavior_ClosePopupOnClick < handle
    % Mixin class inherited by ListItemWithCheckBox,
    % ListItemWIthRadioButton

    % Copyright 2021 The MathWorks, Inc.

    % ----------------------------------------------------------------------------
    properties (Dependent, Access = public, Hidden)
        % Property "closePopupOnClick": 
        %
        %   Whether or not the menu popup should close after clicking on the widget
        %
        %   Example:
        %       item = matlab.ui.internal.toolstrip.ListItemWithCheckBox('Select Me')
        %       item.ClosePopupOnClick = true;
        ClosePopupOnClick
    end

    properties (Access = {?matlab.ui.internal.toolstrip.base.Component})
        ClosePopupOnClickPrivate = false;
    end

    % ----------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        setPeerProperty(this)
    end

    % Public methods
    methods
        %% Public API: Get/Set
        % ClosePopupOnClick
        function value = get.ClosePopupOnClick(this)
            % GET function
            value = this.ClosePopupOnClickPrivate;
        end
        function set.ClosePopupOnClick(this, value)
            % SET function
            if ~islogical(value)
                error(message('MATLAB:toolstrip:control:invalidClosePopupOnClick'))
            end
            this.ClosePopupOnClickPrivate = value;
            this.setPeerProperty('closePopupOnClick',value);
        end
    end

    methods (Access = protected)
        function [mcos, peer] = getWidgetPropertyNames_ClosePopupOnClick(this)
            mcos = {'ClosePopupOnClickPrivate'};
            peer = {'closePopupOnClick'};
        end
    end
end

