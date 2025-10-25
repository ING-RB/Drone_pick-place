classdef CreateAppDDUXLogRunningEventData < event.EventData
    % CREATEAPPDDUXLOGRUNNINGEVENTDATA Event data class for 
    % 'AppDDUXLogRunning' event

%   Copyright 2024 The MathWorks, Inc.

   properties
      App
      Figure
      FileName
   end

   methods
      function data = CreateAppDDUXLogRunningEventData(app, figure, fileName)
         data.App = app;
         data.Figure = figure;
         data.FileName = fileName;
      end
   end
end
