classdef ButtonGroupInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor, option)
            import matlab.uiautomation.internal.InteractorFactory;
            import matlab.uiautomation.internal.MultiLineTextValidator;
            import matlab.uiautomation.internal.UISingleSelectionStrategy;
            
            buttons = actor.Component.Buttons;
            if isempty(buttons)
                chText = {}; % let the validation throw
            else
                chText = {buttons.Text};
            end
            
            strategy = UISingleSelectionStrategy(MultiLineTextValidator, chText);
            index = strategy.validate(option);
            
            % Get the associated handle and redispatch - no need to check
            % if it's already the SelectedObject, its Interactor will figure
            % that out
            button = buttons(index);
            buttonActor = InteractorFactory.getInteractorForHandle(button, actor.Dispatcher);
            uichoose(buttonActor);
        end
        
    end
    
end