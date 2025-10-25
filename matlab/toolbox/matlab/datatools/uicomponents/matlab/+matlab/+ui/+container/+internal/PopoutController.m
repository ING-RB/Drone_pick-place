classdef (Hidden) PopoutController < ...
        matlab.ui.control.internal.controller.ComponentController
    % variableeditorController is the controller for VariableEditor component

    % Copyright 2022-2023 The MathWorks, Inc.

    methods
        function obj = PopoutController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end

        function open(obj)
            % OPEN - Send message to view to open the popout.
            func = @() obj.ClientEventSender.sendEventToClient('open', {});
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
        end

        function close(obj)
            % CLOSE - Send message to view to close the popout.
            func = @() obj.ClientEventSender.sendEventToClient('close', {});
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
        end
    end

    methods(Access = 'protected')
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view

            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);

            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'TargetID'...
                }];
        end

        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);

            %% Event handling goes here
            if(strcmp(event.Data.Name, 'PopoutOpening')) && ~obj.Model.IsOpen
                % Using push button event data, since there isn't any
                % callback data anyway, and this seems to be an empty event
                % data class anyway
                obj.Model.IsOpen = true;
                eventData = matlab.ui.eventdata.ButtonPushedData;
                % Emit 'ButtonPushed' which in turn will trigger the user callback
                obj.handleUserInteraction('PopoutOpening', event.Data, {'PopoutOpening', eventData}); 
            elseif(strcmp(event.Data.Name, 'PopoutClosing')) && obj.Model.IsOpen
                % Using push button event data, since there isn't any
                % callback data anyway, and this seems to be an empty event
                % data class anyway
                obj.Model.IsOpen = false;
                eventData = matlab.ui.eventdata.ButtonPushedData;
                % Emit 'ButtonPushed' which in turn will trigger the user callback
                obj.handleUserInteraction('PopoutClosing', event.Data, {'PopoutClosing', eventData}); 
            end
        end

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handle specific property sets

            %% Special property handling goes here

            % Call the superclasses for unhandled properties
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
    end
end

