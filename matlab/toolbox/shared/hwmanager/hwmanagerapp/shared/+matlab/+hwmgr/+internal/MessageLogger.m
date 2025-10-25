classdef MessageLogger < handle
    % This class will log messages being sent and recieved via the
    % matlabshared.mediator.internal.Mediator class in Hardware Manager.
    % The diagnostic information displayed shows the sequence of messages
    % propagating through Hardware Manager during operation. All Hardware
    % Manager module properties that are registered with the mediator must
    % be set and listened to via this class.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Dependent)
        % ISLOGGING - used to query an env variable to determine whether to
        % display the information logged via the gateways
        IsLogging
    end
    
    properties
        % LogFcn - This is a function handle. This function is invoked if
        % set to capture the property being set and the value the property
        % is set to via the logAndSet() method. This can be used when
        % writing module unit tests to capture messages being sent out from a
        % module.
       LogFcn 
    end
    
    methods
        
        function out = get.IsLogging(~)
            out = ~isempty(getenv('HWMGR_MEDIATOR_LOGGING'));
        end
        
        function logAndSet(obj, propName, propVal)
            % Property change gateway method to log the class instance that the
            % property is being set on and hence generating the event, the name
            % of the property being changed and the value that is assigned to
            % it.
            
            obj.localPrintPropSet(propName, propVal);
            obj.customLogFcn(propName, propVal);
            obj.(propName) = propVal;
        end
        
        
        function logAndInvoke(obj, ~, evt, methodName, propName)
            % Logging gateway method to log the callback method being invoked
            % in response to the associated property change event. The
            % callback method is invoked with the property value as the
            % only input argument.
            
            % The following shows a sample output:
            % 1. The first line shows the class RECEIVING the message
            % 2. The second line shows the CALLBACK FUNCTION invoked in
            % response to the message
            % 
            % "matlab.hwmgr.internal.HwmgrWindow" RECIEVED MESSAGE <<<<<< "MakeWindowBusy": 
            % CALLBACK INVOKED: "matlab.hwmgr.internal.HwmgrWindow.setApplicationModal"

            obj.localPrintCallbackInvoke(methodName, propName);
            obj.(methodName)(evt.AffectedObject.(propName));
        end
        
        function logAndInvokeWithoutArgs(obj, ~, ~, methodName, propName)
            % Logging gateway method to log the callback method being invoked
            % in response to the associated property change event. The
            % callback method will be invoked without any input args.
            
            obj.localPrintCallbackInvoke(methodName, propName);
            obj.(methodName)(); 
        end
        
        function subscribeWithGateways(obj, eventsAndCallbacks, subscribeMethod)
            % This is a utility method that is called by the derived module
            % class's subscribeToMediatorProperties method.
            
            % This method attaches the MessageLogger's logAndInvoke() to
            % all property change events triggered by the mediator. As
            % such, all mediator based messaging will go through the
            % logAndInvoke() method and get logged before the actual
            % callback specified to do the work is actually dispatched.
            
            for i = 1:size(eventsAndCallbacks,1)
                subscribeMethod(eventsAndCallbacks(i, 1), ...
                    @(src,evt)obj.logAndInvoke(src, evt, eventsAndCallbacks(i,2),eventsAndCallbacks(i,1)));
            end
        end
        
        function subscribeWithGatewaysNoArgs(obj, eventsAndCallbacks, subscribeMethod)
             % This is a utility method that is called by the derived module
            % class's subscribeToMediatorProperties method.
            
            % This method attaches the MessageLogger's
            % logAndInvokeWithoutArgs() to all property change events
            % triggered by the mediator. As such, all mediator based
            % messaging will go through the logAndInvokeWithoutArgs()
            % method and get logged before the actual callback specified to
            % do the work is actually dispatched.
            
            for i = 1:size(eventsAndCallbacks,1)
                subscribeMethod(eventsAndCallbacks(i, 1), ...
                    @(src,evt)obj.logAndInvokeWithoutArgs(src, evt, eventsAndCallbacks(i,2),eventsAndCallbacks(i,1)));
            end
        end
    end
   
    methods (Access = private)
        function localPrintPropSet(obj, propName, propVal)
            % The following shows a sample output:
            % 1. The first line shows the class sending the message
            % 2. The second line shows the MESSAGE TITLE (i.e PROPERTY
            % NAME) the data sent along with the message (i.e. the PROPERTY
            % VALUE)

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            % ----------------------------------------------------------------------------------------------------
            % OUTGOING MESSAGE >>>>> from "matlab.hwmgr.internal.MainController":
            %  "MakeWindowBusy" || VALUE =
            %    1
            if obj.IsLogging
                fprintf(['\n\n\n' repmat('%', [1 200])  ' \n']);
                fprintf([repmat('-',[1 100]) ' \n']);
                                
                fprintf('OUTGOING MESSAGE >>>>> from "%s": \n "%s" || VALUE = \n', class(obj), propName);
                disp(propVal);
            end
        end
        
        function localPrintCallbackInvoke(obj,methodName,propName)
            % The following shows a sample output:
            % 1. The first line shows the class RECEIVING the message
            % 2. The second line shows the CALLBACK FUNCTION invoked in
            % response to the message
            % 
            % "matlab.hwmgr.internal.HwmgrWindow" RECIEVED MESSAGE <<<<<< "MakeWindowBusy": 
            % CALLBACK INVOKED: "matlab.hwmgr.internal.HwmgrWindow.setApplicationModal"
             if obj.IsLogging
                fprintf('\n');
                fprintf('"%s" RECIEVED MESSAGE <<<<<< "%s": \n       CALLBACK INVOKED: "%s.%s"\n', class(obj), propName, class(obj), methodName);
            end
        end
        
        function customLogFcn(obj, propName, propVal)
             if ~isempty(obj.LogFcn)
                obj.LogFcn(propName, propVal);
            end 
        end

    end
    
end
