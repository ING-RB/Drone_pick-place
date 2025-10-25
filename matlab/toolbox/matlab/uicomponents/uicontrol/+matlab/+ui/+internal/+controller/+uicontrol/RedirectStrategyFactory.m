classdef RedirectStrategyFactory < handle
    %

    % Copyright 2019-2020 The MathWorks, Inc.

    methods
        function strategy = getRedirectStrategy(obj, uicontrolModel)
            import matlab.ui.internal.controller.uicontrol.*;

            switch uicontrolModel.Style
                case 'pushbutton'
                    strategy = PushButtonRedirectStrategy();
                case 'listbox'
                    strategy = ListboxRedirectStrategy();
                case 'togglebutton'
                    % When the UIControl is parented to a button group, it should
                    % always respect the mutual exclusive property of the button group.
                    % Using a state button allows interactive deselection of all buttons
                    % in the button group, which is different from Java behavior.  Using a
                    % toggle button will ensure that the user cannot interactively
                    % deselect all of the buttons.
                    if isa(uicontrolModel.Parent, 'matlab.ui.container.ButtonGroup')
                        strategy = ToggleButtonRedirectStrategy();
                    else
                        strategy = StateButtonRedirectStrategy();
                    end
                case {'checkbox', 'radiobutton'}
                    % When CData is set on the uicontrol, it is being used
                    % to display an image.  In this case we should redirect
                    % to the Image component to display the image.  In Java
                    % the checkbox would be completely replaced with the
                    % image represented by the value of CData.

                    if isempty(uicontrolModel.CData)
                        switch uicontrolModel.Style
                            case 'checkbox'
                                strategy = CheckboxRedirectStrategy();
                            case 'radiobutton'
                                strategy = RadioButtonRedirectStrategy();
                        end

                        % If the uicontrol is parented, add a decorator
                        % strategy to display a label behind the component
                        % to show its background color.
                        if ~isempty(uicontrolModel.Parent)
                            label = obj.createBackgroundColorLabel(uicontrolModel);
                            strategy = matlab.ui.internal.controller.uicontrol.BackgroundColorStrategyDecorator(strategy, label);
                        end
                    else
                        strategy = ImageRedirectStrategy();
                    end
                case 'edit'
                    strategy = EditFieldRedirectStrategy();
                case 'text'
                    strategy = TextRedirectStrategy();
                case 'slider'
                    strategy = SliderRedirectStrategy();
                case 'popupmenu'
                    strategy = PopupMenuRedirectStrategy();
                case 'frame'
                    strategy = FrameRedirectStrategy();
                otherwise
                    error('unknown!')
            end
        end

        function label = createBackgroundColorLabel(~, uicontrolModel)
            label = matlab.ui.control.Label(...
                'Parent', [], ...
                'BackgroundColor', uicontrolModel.BackgroundColor, ...
                'Position', uicontrolModel.Position, ...
                'Text', '', ...
                'Visible', uicontrolModel.Visible);
            % Disable view property cache performance optimization for uicontrol
            % redirection, which may has more issues to enable it
            % Todo: consider enabling it in the future
            label.disableCache();

            % Tell the client to treat the Label as a UIControl.  This
            % enables use of normalized units for the Label.
            label.setUIControlModel(uicontrolModel);
        end
    end
end
