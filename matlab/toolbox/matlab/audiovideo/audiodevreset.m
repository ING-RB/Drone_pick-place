function audiodevreset
%AUDIODEVRESET Reset the list of audio devices.
%   AUDIODEVRESET resets the list of available audio devices. Use
%   AUDIODEVRESET to refresh the list of available devices after an audio
%   device has been added to or removed from the machine.
%
% Example:
%      % Refresh the list of available devices after 
%      % plugging in a new audio device
%      audiodevreset
%      % Return information about devices including the new one
%      audiodevinfo 
%      
%   See also AUDIODEVINFO, AUDIOPLAYER, AUDIORECORDER.

%   Copyright 2020-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;
if Capability.isSupported(Capability.LocalClient)
    multimedia.internal.audio.device.DeviceInfo.reset
else
    audiovideo.internal.audio.utility.resetAudioDevices;
end
