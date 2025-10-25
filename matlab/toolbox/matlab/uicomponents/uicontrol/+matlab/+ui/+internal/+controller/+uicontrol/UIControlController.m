classdef UIControlController < matlab.ui.internal.componentframework.WebComponentController
    % UICONTROLCONTROLLER Web-based controller base class for uicontrol.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(Access = 'protected')
        ContextMenuBehavior
        UIControlCommonBehavior
    end

    properties (Access = private)
        figureActivatedListener = [];
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Constructor
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = UIControlController( model, varargin  )
            % Super constructor
            obj = obj@matlab.ui.internal.componentframework.WebComponentController(model, varargin{:});

            pms = obj.PropertyManagementService;
            obj.UIControlCommonBehavior = matlab.ui.internal.controller.uicontrol.UIControlPropertyManager(pms);
            obj.ContextMenuBehavior = matlab.ui.internal.componentframework.services.optional.HasContextMenuBehaviorAddOn(pms);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:      bringToFocus
        %
        %  Description: Requests that the UIControl be brought to focus
        %
        %  Inputs :     None.
        %  Outputs:
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function bringToFocus(obj)
            % Follow same logic implemented in FocusableController for
            % g2995579 and g3464888
            topLevelAncestor = ancestor(obj.Model, 'figure', 'toplevel');
            if ~isempty(topLevelAncestor)
                % This will make sure that controllers are created. 
                % It is also necessary that we start this before we check
                % if the figureController is active. 
                matlab.graphics.internal.drawnow.startUpdate

                figureController = getParentFigureController(obj);
                if ~isempty(figureController) && figureController.IsActive
                    % Figure is already to front, focus the component
                    func = @() obj.EventHandlingService.dispatchEvent('FocusComponent');
                    matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
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
    end

    methods(Access = 'protected')
        function postAdd(obj)

            obj.EventHandlingService.attachEventListener(@obj.handleEvent);
        end

        function triggerActionEvent(obj)
            selectionType = ancestor(obj.Model, 'figure').SelectionType;
            obj.Model.processActionEvent(selectionType);
        end

        function triggerContinuousValueChangeEvent(obj)
            obj.Model.processContinuousValueChangeEvent();
        end

        function processStringChanged(obj, event)
            obj.Model.updateStringFromView(event.Data.Value);
        end

        function processValueChanged(obj, event)
            newVal = event.Data.Value;
            obj.updateValueFromView(newVal);
        end

        function updateValueFromView(obj, newVal)
            obj.Model.updateValueFromView(newVal);
        end

        function processValueChangedFromSelection(obj, event)
            newVal = event.Data.SelectedIndex;
            % UIControl selection should never have a value of -1
            % -1 in the web world represents no selection
            % In Java it was [];
            if newVal == -1
                newVal = [];
            end
            obj.Model.updateValueFromView(newVal);
        end

        function handleEvent(obj, src, event)
            %Java didnt send TAB key interactions. Web does. 
            % We should only respond to these with radiouttons
           if (strcmp(event.Data.Name, 'processKeyEvent') && strcmp(event.Data.data.key,'tab') && ~strcmp(obj.Model.Style,'radiobutton'))
                return
            end
            handleEvent@matlab.ui.internal.componentframework.WebComponentController(obj, src, event);
            switch event.Data.Name
                case 'SizeLocationChanged'
                    pos = event.Data.Position.Value;
                    if (~isfield(event.Data.Position, 'RefFrameSize'))
                        return;
                    end
                    refFrame = [1 1 event.Data.Position.RefFrameSize];
                    obj.Model.setPositionFromClient('positionChangedEvent', ...
                        pos, ...
                        pos,...
                        refFrame);
            end
        end

        % Methods for programmatic focus
        function dispatchFocusEventToComponent(obj)
            if (~isempty(obj))
                cleanup = onCleanup(@()destroyFocusListener(obj));
                func = @() obj.EventHandlingService.dispatchEvent('FocusComponent');
                matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
            end
        end

        function figureController = getParentFigureController(obj)
            figureController = obj;
            while ~isempty(figureController) && ~isa(figureController, 'matlab.ui.internal.controller.FigureController')
                figureController = figureController.ParentController;
            end
        end

        function destroyFocusListener(obj)
            delete(obj.figureActivatedListener);
            obj.figureActivatedListener = [];
        end
    end

    methods
        
        function val = fallbackDefaultBackgroundColor ( ~ )
            val = [];
        end

        function val = updateIsUIControl(obj)
            val = true;
        end

        function val = updateUIControlEnable(obj)
            val = obj.Model.Enable;
        end

        function val = updateFontAngle(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertFontAngle;
            val = convertFontAngle(obj.Model.FontAngle);
        end

        function newFontName = updateFontName(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertFontName;
            newFontName = convertFontName(obj.Model.FontName);
        end

        function val = updateFontColor(obj)
            val = obj.Model.ForegroundColor;
        end

        function val = updateFontSize(obj)
            fSize = obj.Model.FontSize;
            fUnits = obj.Model.FontUnits;

            val = struct("FontSize",fSize, "FontUnits", fUnits);
        end

        function newPosValue = updatePosition(obj)
            model = obj.Model;
            newPosValue = matlab.ui.internal.componentframework.services.core.units.UnitsServiceController.getUnitsValueDataForView(model);
        end

        function pvp = updateFontWeight(obj)
            fontWeight = obj.Model.FontWeight;

            % The values 'light' and 'demi' are no longer supported.
            % Convert them to 'normal' and don't create an issue as this is
            % a minor cosmetic difference.
            if strcmpi(fontWeight, 'light') || strcmpi(fontWeight, 'demi')
                fontWeight = 'normal';
            end
            pvp = {'FontWeight', fontWeight};
        end

        function val = updateBackgroundColor(obj)
            import matlab.ui.internal.controller.uicontrol.UIControlConversionRules.convertBackgroundColorIfDefault;
            revertDefaultsIfEqual = obj.fallbackDefaultBackgroundColor();
            val = convertBackgroundColorIfDefault(obj.Model.BackgroundColor, revertDefaultsIfEqual);
        end

        function newContextMenuID = updateContextMenuID( obj )
            newContextMenuID = obj.ContextMenuBehavior.updateContextMenuID(obj.Model.UIContextMenu);
        end
    end
end
