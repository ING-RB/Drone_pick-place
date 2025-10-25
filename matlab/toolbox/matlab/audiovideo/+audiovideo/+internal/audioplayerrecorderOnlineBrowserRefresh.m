classdef audioplayerrecorderOnlineBrowserRefresh < handle
    % This class is used in reconstructing the audioplayerOnline and
    % audiorecorderOnline objects when the browser is refreshed by the user
    % in MATLAB Online
    
    % Copyright 2020-2022 The MathWorks, Inc.
   properties (Constant)
      Instance = audiovideo.internal.audioplayerrecorderOnlineBrowserRefresh
   end
   events
       reconnectWithDevice
   end
   
    methods
        function notifyAllAudioPlayerRecorderOnline(obj)
            notify(obj, 'reconnectWithDevice');
        end
    end  
end