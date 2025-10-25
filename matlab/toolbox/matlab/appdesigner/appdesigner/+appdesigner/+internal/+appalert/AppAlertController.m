classdef AppAlertController < handle
    %APPALERTCONTROLLER Mixin controller class to send app startup and
    %run time alerts to the client.
    
    % Copyright 2014 - 2021 The MathWorks, Inc.  
    
    properties(Access = protected)
        % Listen to 'CallbackErrored' events from CallbackErrorHandler
        CallbackErroredListener
        
        % Listen to 'UpdateException' events from ComponentContainer
        UpdateErroredListener
    end
    
    methods(Abstract, Access = protected)
        doSendErrorAlertToClient(obj, appException)
            % DOSENDERRORALERTTOCLIENT(obj, appException) sends app
            % startup/run-time error information to the client.
            %
            % Inputs:
            %
            % appException - a decorated MException with a truncated stack
    end
    
    methods
        
        function sendErrorAlertToClient(obj, mException, appFullFileName)
            % SENDERRORALERTTOCLIENT(obj, mException, appFullFileName)
            % Creates an AppException based on the MException that the
            % app threw upon instantiation or callback execution and
            % sends it to the client.
            %
            % Inputs:
            %
            % mException - MException thrown by the running app
            %
            % appFullFileName - The full file name of the running app
            
            if(~isa(mException, 'appdesigner.internal.appalert.AppArgumentException'))
                appException = appdesigner.internal.appalert.AppException(...
                    mException, appFullFileName);
            else
                appException = mException;
            end
            
            obj.doSendErrorAlertToClient(appException);
        end
        
        function addErrorAlertListener(obj, appModel)
            % ADDERRORALERTLISTENER(obj, appModel)
            % Adds a listener for when a run time error occurs in the app.
            % 
            % Inputs:
            % appModel - The AppModel of the running app
            
            callbackErrorHandler = appdesigner.internal.apprun.CallbackErrorHandler.instance();
            
            if isempty(obj.CallbackErroredListener)
                obj.CallbackErroredListener = addlistener(callbackErrorHandler, 'CallbackErrored',...
                    @(src,event)handleCallbackErrored(obj, src, event, appModel));
            end
        end
        
        function addUpdateExceptionAlertListener(obj, runningComponent, fullFileName)
            % Listen for the update exception coming from the custom ui
            % component
            
            if ~isempty(obj.UpdateErroredListener)
                delete(obj.UpdateErroredListener)
            end
            
            obj.UpdateErroredListener = addlistener(runningComponent, 'UpdateError',...
                @(src, event)handleUpdateException(obj, event, fullFileName));
        end
        
        function delete(obj)
            % DELETE(OBJ) delete the controller.
            %
            % Cleans up the listener
            
            if ~isempty(obj.CallbackErroredListener)
                delete(obj.CallbackErroredListener);
            end
            
            if ~isempty(obj.UpdateErroredListener)
                delete(obj.UpdateErroredListener);
            end
        end
    end
    
    methods(Access = private)
        function handleUpdateException(obj, event, fullFileName)
            obj.sendErrorAlertToClient(event.Exception, fullFileName);
        end
        
        function handleCallbackErrored(obj, ~, event, appModel)
            % Private handler for all events being fired from a running app
            appFullFileName = appModel.FullFileName;            
            isMyAppErrored = false;
            
            if isempty(event.AppFullFileName) && ...
                   appModel.IsDebugging && ...
                   ~isempty(find(strcmp(appFullFileName, {event.Exception.stack.file}), 1))
                % If the event has an empty AppFullFileName passed in, it
                % means the app is run from MATLAB, which triggers debug
                % state in App Designer. Under such a scenario, need to
                % ensure LiveAlert work, see g1502397
                isMyAppErrored = true;
            elseif strcmp(event.AppFullFileName, appFullFileName)
                isMyAppErrored = true;                
            end
            
            if isMyAppErrored
                obj.sendErrorAlertToClient(event.Exception, appFullFileName);
            end
        end
    end
end