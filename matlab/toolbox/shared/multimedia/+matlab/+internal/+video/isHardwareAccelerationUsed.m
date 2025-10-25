function useHwAccel = isHardwareAccelerationUsed()
% ISHARDWAREACCELERATIONUSED Determine the state of the hardware
% acceleration option that is to be used when reading videos.
% This currently applies only on Windows

%   Copyright 2018 The MathWorks, Inc.

    switch( matlab.video.read.UseHardwareAcceleration )
        case 'on'
            useHwAccel = true;
        case 'off'
            useHwAccel = false;
        otherwise
            assert(false, 'Invalid hardware acceleration mode');
    end