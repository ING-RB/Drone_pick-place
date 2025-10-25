classdef (Abstract) ActionBehavior_Text < handle
    % Mixin class inherited by Buttons, ListItems, Label, CheckBox,
    % RadioButton and PopupListHeader
    
    % Copyright 2013-2019 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Access = private)
        handledExceptionTypes = {'MATLAB:class:SetProhibited'};
    end
    
    properties (Dependent, Access = public)
        % Property "Text": 
        %
        %   It is a string and the default value is ''.
        %   It is writable.
        %
        %   Example:
        %       btn = matlab.ui.internal.toolstrip.Button
        %       btn.Text = 'Submit'
        Text
    end
    
    methods (Abstract, Access = protected)
        
        getAction(this)
        
    end
    
    %% ----------------------------------------------------------------------------
    % Public methods
    methods
        
        %% Public API: Get/Set
        function value = get.Text(this)
            % GET function
            action = this.getAction;
            value = action.Text;
        end
        function set.Text(this, value)
            % SET function
            try
                this.set_Text(value);
                this.handleActionTextUpdate(value);
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
        function set_Text(this, value)
            % SET function implementation for Text property
            action = this.getAction();
            action.Text = value;
        end
        
        function handleActionTextUpdate(this, value)
            % Inherited classes can override this method
            % to handle text updates. Currently used for
            % g2345953
        end
    end
    
end
