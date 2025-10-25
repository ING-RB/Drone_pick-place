classdef EventDispatcherAddOn < handle
% EVENTDISPATCHERADDON - Mixin for controllers of components that support
% event coalescing. 

% Copyright 2020 The MathWorks, Inc.

    methods         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      sendFlushEventToClient
         %
         %  Description: Sends 'flush' event to client to indicate that an
         %               event in the CoalescedEvents list is ready to
         %               process
         % Inputs:
         %
         %   obj       - Controller object
         %   model     - Component model
         %   eventName - Name of the event being processed
         %   ehs       - Controller's EventHandlingService (EHS) if one exists.
         %               Legacy components have an EHS, but new UI Components do not.
         %
         %  Outputs:     None
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function sendFlushEventToClient(obj, model, eventName, ehs)
             % Need to check if ProxyView is valid or not because
             % the user's callback could delete the app or the component
             % see g1336677
             if(~isempty(obj.ViewModel))
                 % When peer node view is ready, send 'flush' event to client
                 % in the format {'Name', 'flush', 'WidgetEvent', eventName}
                 pvPairs = {'WidgetEvent', eventName};
                 % If the controller has an EHS, use dispatchEvent()
                 % Otherwise, use sendEventToClient()
                 if nargin == 4
                     func = @() ehs.dispatchEvent('flush', pvPairs);
                 else
                     func = @() obj.ClientEventSender.sendEventToClient('flush', pvPairs);
                 end
                 matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(model, obj.ViewModel, func);
             end
         end
    end
end
