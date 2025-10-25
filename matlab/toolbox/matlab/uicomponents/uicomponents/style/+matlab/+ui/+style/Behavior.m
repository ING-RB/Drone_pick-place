classdef (Hidden) Behavior < matlab.ui.style.internal.ComponentStyle
    %

    % Do not remove above white space
    % Copyright 2021 The MathWorks, Inc.

    properties
        Editable = '';
    end

    properties (Access = ?matlab.ui.style.internal.ComponentStyle)
        DisplayPropertyOrder = ["Editable"];
    end

    methods
        function obj = Behavior(varargin)
            obj = obj@matlab.ui.style.internal.ComponentStyle(varargin{:});
        end

        function obj = set.Editable(obj, newEditable)
            
            % Error Checking
            % Allow scalar OnOffSwitchState and empty
            isOnOffSwitchState = ismember(newEditable, [matlab.lang.OnOffSwitchState('on'), matlab.lang.OnOffSwitchState('off')]);
            if isscalar(isOnOffSwitchState) && isOnOffSwitchState
                newEditable = matlab.lang.OnOffSwitchState(newEditable);
            elseif isequal(newEditable,'')
                newEditable = '';
            else
                messageObj = message('MATLAB:ui:components:invalidThreeStringEnum', ...
                    'Editable', 'on', 'off', '');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidEditable';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
            end
            
            % Property Setting
            obj.Editable = newEditable;
        end
    end
end