classdef CreateAppDDUXTimingMarkerEventData < event.EventData
    % CREATEAPPDDUXTIMINGMARKEREVENTDATA Event data class for 
    % 'AppDDUXTimingMarker' event

%   Copyright 2024 The MathWorks, Inc.

   properties
       App
       DDUXField
       MarkerTime
   end

   methods
      function data = CreateAppDDUXTimingMarkerEventData(App, DDUXField)
          data.App = App;
          data.DDUXField = DDUXField;
          data.MarkerTime = string(datetime('now', 'TimeZone', 'GMT', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
      end
   end
end
