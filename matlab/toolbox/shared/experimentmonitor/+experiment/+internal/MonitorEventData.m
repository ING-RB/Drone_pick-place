classdef (ConstructOnLoad) MonitorEventData < event.EventData
%

%   Copyright 2022 The MathWorks, Inc.

   properties
      data
   end
   
   methods
      function this = MonitorEventData(evtData)
         this.data = evtData;
      end
   end
end
