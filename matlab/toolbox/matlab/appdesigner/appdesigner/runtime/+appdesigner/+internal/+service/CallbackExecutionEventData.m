classdef CallbackExecutionEventData < event.EventData
    % CALLBACKBEINGEXECUTEDEVENTDATA Event data class for 
    % 'CallbackErrored' event

    % Copyright 2021 The MathWorks, Inc.

   properties
      Object
   end

   methods
      function data = CallbackExecutionEventData(obj)
         data.Object = obj;
      end
   end
end
