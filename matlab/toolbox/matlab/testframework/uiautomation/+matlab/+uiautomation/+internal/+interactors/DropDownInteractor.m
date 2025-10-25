classdef DropDownInteractor < ...
        matlab.uiautomation.internal.interactors.AbstractStateComponentInteractor & ...
        matlab.uiautomation.internal.interactors.mixin.TextTypable
    % This class is undocumented and subject to change in a future release

    % Copyright 2017-2023 The MathWorks, Inc.

    methods
        function uichoose(actor, option)
            import matlab.uiautomation.internal.UISingleSelectionStrategy;
            import matlab.uiautomation.internal.SingleLineTextValidator;

            narginchk(2,2)
            component = actor.Component;

            strategy = UISingleSelectionStrategy(SingleLineTextValidator, component.Items);
            if isequal(component.SelectedIndex, strategy.option2indices(option))
                return;
            end

            % Expand to let DropDownOpeningFcn run which may change the
            % items in the DropDown.
            actor.Dispatcher.dispatch(component, 'uipress', 'ExpandOnly', true);

            strategy = UISingleSelectionStrategy(SingleLineTextValidator, component.Items);
            index = strategy.validate(option);

            actor.Dispatcher.dispatch(component, 'uipress', 'Index', index);
        end
    end
end

% LocalWords:  Interactor Typable uichoose uipress
