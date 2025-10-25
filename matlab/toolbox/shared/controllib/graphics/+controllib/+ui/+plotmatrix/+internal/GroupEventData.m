classdef (ConstructOnLoad) GroupEventData < event.EventData
%

%   Copyright 2015-2020 The MathWorks, Inc.

   properties
      Name
      OldValue
   end

   methods
      function data = GroupEventData(name,oldValue)
         data.Name = name;
         data.OldValue = oldValue;
      end
   end
end
