classdef (Abstract) SelctionTypeInteractorHelper < handle
% SelctionTypeInteractorHelper contains common helper functions to
% determine the SelectionType/Button-Modifier combinations for press API
%
% This class is for internal use only and may change in the future.

% Copyright 2022 The MathWorks, Inc.
    
    methods (Access = protected)
        function button = getButton(actor, buttonVal)
            % Method validates string buttonVal input and returns the
            % button
            if(~isempty(buttonVal))
                buttonType = validatestring(buttonVal, ...
                    ["left" "middle" "right"]);
                button = actor.getButtonType(buttonType);
            end
        end

        function modifier = getModifier(actor, modifierVal)
            % Method validates string modifierVal input and returns the
            % modifier
            if(~isempty(modifierVal))
                modifierType = validatestring(modifierVal, ...
                    ["ctrl" "shift" "alt" "meta"]);
                modifier = actor.getModifierType(modifierType);
            end
        end

        function button = getButtonType(~, buttonType)
            % Method obtains the button based on the string buttonType
            % supplied
            import matlab.uiautomation.internal.Buttons;

            buttons = dictionary(["left", "middle", "right"], [Buttons.LEFT, Buttons.MIDDLE, Buttons.RIGHT]);
            button = buttons(buttonType); 
        end
        
        function modifier = getModifierType(~, modifierType)
            % Method obtains the modifier based on the string modifierType
            % supplied
            import matlab.uiautomation.internal.Modifiers;
        
            modifiers = dictionary(["ctrl", "shift", "alt", "meta"], [Modifiers.CTRL, Modifiers.SHIFT, Modifiers.ALT, Modifiers.META]);
            modifier = modifiers(modifierType);
        end

        function out = validateSelectionType(~, value)
            % Method validates SelectionType
            validatestring(value, ["normal" "extend" "alt" "open"]);
            out = value;
        end 

        function bool = checkIfSelectionTypeButtonModifierUsedTogether(~, parser)
            % Method checks if SelectionType and Button-Modifier
            % parameters are not supplied together
                  
            bool = ~ismember("SelectionType", parser.UsingDefaults) && ...
                any(~ismember(["Button", "Modifier"], parser.UsingDefaults));
        end
    end
end