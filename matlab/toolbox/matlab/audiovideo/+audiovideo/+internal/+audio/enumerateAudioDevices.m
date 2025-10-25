classdef enumerateAudioDevices < handle
    % This class acts as a static data object for
    % audiovideo.internal.audio.utility class and tracks whether the list
    % of audio output devices needs to be regenerated
    
    % Copyright 2020-2022 The MathWorks, Inc.
   properties
      Enumerate = true
   end
end
