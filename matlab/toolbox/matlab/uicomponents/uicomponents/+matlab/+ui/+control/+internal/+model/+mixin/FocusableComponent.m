classdef (Hidden) FocusableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin

    properties (Access = private)
        figureActivatedListener = [];
    end

    methods
        function focus(obj)
            %FOCUS Focus UI component
            %
            %   FOCUS(c) gives keyboard focus to the UI component c and brings its parent figure to the front
            %
            %   See also UIFIGURE, UITABLE, UIBUTTON, UIEDITFIELD

            %   Copyright 2021 The MathWorks, Inc.

            % Turn off warning backtrace, and then reinstate it on cleanup
            w = warning('backtrace', 'off');
            cleanup = onCleanup(@()warning(w));

            % warn and do not focus when Visible or Enable property is 'off'
            if isprop(obj, 'Visible') && strcmp(obj.Visible, 'off')
                msgTxt = getString(message('MATLAB:ui:components:NotFocusable',...
                    'Visible','off'));
                mnemonicField = 'NotFocusable';
                matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
                return;
            elseif isprop(obj, 'Enable') && strcmp(obj.Enable, 'off')
                msgTxt = getString(message('MATLAB:ui:components:NotFocusable',...
                    'Enable','off'));
                mnemonicField = 'NotFocusable';
                matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
                return;
            end

            % If component-specific validation returns false, return here
            % so we do not attempt to focus
            isValid = isConfigurationFocusable(obj);
            if ~isValid
                return;
            end

            % Returns the top-level Figure ancestor if one exists. Otherwise [].
            topLevelAncestor = ancestor(obj, 'figure', 'toplevel');
            if ~isempty(topLevelAncestor)
                % warn and do not focus when parent figure is invisible
                if strcmp(topLevelAncestor.Visible, 'off')
                    msgTxt = getString(message('MATLAB:ui:components:FigureNotFocusable'));
                    mnemonicField = 'FigureNotFocusable';
                    matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj,mnemonicField,msgTxt);
                    return;
                end
                % This will make sure that controllers are created. 
                % It is also necessary that we start this before we check
                % if the figureController is active. 
                matlab.graphics.internal.drawnow.startUpdate

                figureController = getParentFigureController(obj);
                if ~isempty(figureController) && figureController.IsActive
                    % Figure is already to front, focus the component
                    controller = obj.getController();
                    func = @() controller.ClientEventSender.sendEventToClient('FocusComponent', {});
                    matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj, controller.ViewModel, func);
                else
                    % Otherwise, bring the parent figure to front
                    % g2995579: When the CEF window is activated, it seems to be clearing focus from the window and resetting it to whatever was active when the CEF window was last deactivated.
                    % Programmatic focus has been running into a race condition where the figure window is activated after focus is set on the component, which removes focus from the desired component, 
                    % and puts it back on whatever was in focus before. Until we get a fix from CEF 3p, we should hold off on focusing the component until we get confirmation that the figure 
                    % activation has already occurred and cleared focus. Note that this will result in a focus flash.
                    obj.figureActivatedListener = addlistener(topLevelAncestor,'FigureActivated', @(o,e)dispatchFocusEventToComponent(obj));
                    figure(topLevelAncestor);
                end
            end
        end

        function delete(obj)
            destroyFocusListener(obj);
        end
    end

    methods (Access=protected)

        function isFocusable = isConfigurationFocusable(obj)
            % ISCONFIGURATIONFOCUSABLE - This function validates
            % whether the component is in a focusable state. By default,
            % return true. Override as needed in subclasses.
            isFocusable = true;

        end

        function dispatchFocusEventToComponent(obj)
            if (~isempty(obj))
                cleanup = onCleanup(@()destroyFocusListener(obj));
                controller = obj.getController();
                func = @() controller.ClientEventSender.sendEventToClient('FocusComponent', {});
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj, controller.ViewModel, func);
            end
        end

        function figureController = getParentFigureController(obj)
            figureController = obj.getController();
            while ~isempty(figureController) && ~isa(figureController, 'matlab.ui.internal.controller.FigureController')
                figureController = figureController.ParentController;
            end
        end

        function destroyFocusListener(obj)
            delete(obj.figureActivatedListener);
            obj.figureActivatedListener = [];
        end
    end
end