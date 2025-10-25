classdef HTMLController < ...
        matlab.ui.control.internal.controller.ComponentController & ...
        matlab.ui.control.internal.controller.mixin.InternalHTMLController
    % Generic controller to render HTML links or raw HTML code
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    methods(Access = 'public')
        function obj = HTMLController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
        
        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time
            %
            %
            % Do not send 'Data' because it is not actually needed by
            % runtime, only the JSON version is needed
            
            excludedPropertyNames = {'Data'};
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.ComponentController(obj, proxyView);
            
            obj.flushQueuedEventsToView();
        end
        
        function flushQueuedEventsToView(obj)            
            % This will take all events queued up through
            % dispatchEvent(htmlComponentModel) and send them to the view
            % when the View is created + ready
            %
            % Once sent, the events are cleared from the model                      
            if ~isempty(obj.ViewModel)                
                queuedEvents = obj.Model.PrivateEventsToHTMLSource();                
                obj.Model.PrivateEventsToHTMLSource = {};
                if ~isempty(queuedEvents)
                    matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, ...
                        @(varargin) flushedQueuedEventsCallback(obj, queuedEvents));
                end
            end            
        end
        
        function flushedQueuedEventsCallback(obj, queuedEvents)
            % This is the callback that sends each event             
            
            for idx = 1:length(queuedEvents)
                queuedEvent = queuedEvents{idx};
                eventName = queuedEvent{1};
                eventData = queuedEvent{2};
                
                obj.ClientEventSender.sendEventToClient(obj.UserEventFromServer,...
                    {...
                    'EventName', eventName, ...
                    'Data', eventData ...
                    });
            end
        end       
    end
    
    methods(Access = 'protected')

        function handleEvent(obj, src, event)
            if(strcmp(event.Data.Name, 'DataChanged'))
                % Handles when Data is changed from the client
                
                % Get the previous value of Data
                previousValue = obj.Model.Data;
                
                % take the JSON representation and turn into MATLAB data
                newValue = event.Data.DataJSON;
                newMATLABValue = jsondecode(newValue);
                
                % Create event data
                matlabEventData = matlab.ui.eventdata.DataChangedData(newMATLABValue, previousValue);
                
                % Silently update 'Data'
                %
                % JS precision from a user can cause slight
                % floating point rounding differences between client /
                % server.  If we update Data, then it will be re-pushed to
                % the view, and the client will interpret this as a change,
                % and the client side DataChanged event will fire when it
                % should not.
                %
                % g1991717
                obj.Model.PrivateData = newMATLABValue;
                
                % Emit 'DataChanged' which in turn will trigger the user callback
                obj.handleUserInteraction('DataChanged', event.Data, {'DataChanged', matlabEventData});
                
            elseif(strcmp(event.Data.Name, obj.UserEventFromClient))                
                % Handles a user event from the client
                
                name = event.Data.EventName;                                   
                
                % EventData is optional
                %
                % If its sent from the client, since the value is
                % undefiend, it is removed.  Need to check explicitly
                if(isfield(event.Data, 'EventData'))
                    data = event.Data.EventData;
                else
                    data = [];
                end
                
                % Create event data
                matlabEventData = matlab.ui.eventdata.HTMLEventReceivedData(name, data);
                
                % Emit 'EventDispatched' which in turn will trigger the user callback
                obj.handleUserInteraction('HTMLEventReceived', event.Data, {'HTMLEventReceived', matlabEventData});
                
            elseif(strcmp(event.Data.Name, obj.UserErrorFromClient))
                % Turn off callstack for warning: by default the
                % warning will include the callstack
                w = warning('off', 'backtrace');
                warning('MATLAB:ui:uihtml:ErrorOccuredInHTMLSource', getString(message('MATLAB:ui:components:ErrorOccuredInHTMLSource')));
                % Restore warning state
                warning(w);
            else
                handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            end
        end

        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view
            
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; obj.AdditionalProperties];
        end

        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            viewPvPairs = {};
            
            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames), ...
                ];
            viewPvPairs = getCompletePropertiesForView(obj, propertyNames, viewPvPairs);
        end
    end

    methods(Static)        
        function [source, type, html] = formatHTMLSource(source)
            [source, type, html] = matlab.ui.control.internal.controller.mixin.InternalHTMLController.getHTMLSourceAndType(source);
        end
    end
end