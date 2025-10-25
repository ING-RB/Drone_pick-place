classdef (ConstructOnLoad) EventDataContainer < event.EventData
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2021 The MathWorks, Inc.
   properties
      Data = []
   end
   methods
      function eventData = EventDataContainer(value)
         eventData.Data = value;
      end
   end
end