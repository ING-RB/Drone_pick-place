classdef (Abstract) ActionBehavior_Icon < handle
    % Mixin class inherited by Button, DropDownButton, SplitButton,
    % ToggleButton, Label, ListItem, ListItemWIthPopupList
    
    % Copyright 2013-2019 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Access = private)
        handledExceptionTypes = {'MATLAB:class:SetProhibited'};
    end
    
    properties (Dependent, Access = public)
        % Property "Icon": 
        %
        %   Icon used in a control. It is a matlab.ui.internal.toolstrip.Icon object
        %   and the default value is []. It is writable.
        %
        %   Example:
        %       btn = matlab.ui.internal.toolstrip.Button
        %       btn.Icon = matlab.ui.internal.toolstrip.Icon.MATLAB_24
        Icon
    end
    
    methods (Abstract, Access = protected)
        
        getAction(this)
        
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Public API: Get/Set
        function value = get.Icon(this)
            % GET function
            action = this.getAction;
            value = action.Icon;
        end
        
        function set.Icon(this, value)
            % SET function
            try
                this.set_Icon(value);
            catch me
                if any(contains(this.handledExceptionTypes, me.identifier))
                    throwAsCaller(me);
                else
                    rethrow(me);
                end
            end
        end
        
    end

    % Protected methods
    methods (Access = protected)
        function set_Icon(this, value)
            % SET function implementation for Icon property
            action = this.getAction();
            action.Icon = value;
        end
    end
    
end

