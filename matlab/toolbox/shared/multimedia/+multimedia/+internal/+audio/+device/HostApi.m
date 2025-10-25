classdef HostApi < int32
    %HOSTAPI defines audio host APIs for each platform
    %   A HostApi is an ID which defines which audio driver model to use on
    %   a given platform.  HostApi IDs are numbered to match the IDs of the
    %   audiodevice plugin implemented in audiovideo/src/audio.
      
    % Author(s): NH
    % Copyright 2010-2016 The MathWorks, Inc.
 
    % Host API IDs are numbered to match those in the underlying
    % portaudio based audiodevice plugin.
    enumeration
        DirectSound (1)
        ASIO        (3)
        CoreAudio   (5)
        OSS         (7)
        ALSA        (8)
        Default     (multimedia.internal.audio.device.HostApi.getDefault)
    end

    
    methods (Access='private', Static)
        function hostApi = getDefault
            import multimedia.internal.audio.device.HostApi;
            if ispc
                hostApi = HostApi.DirectSound;
            elseif ismac
                hostApi = HostApi.CoreAudio;
            elseif isunix % e.g. Linux
                hostApi = HostApi.ALSA;
            else
                error(message('multimedia:audiodevice:UnsupportedPlatform'));
            end
        end
    end
    
end
