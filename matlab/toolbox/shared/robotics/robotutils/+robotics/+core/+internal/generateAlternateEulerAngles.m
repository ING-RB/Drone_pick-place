function eulAlt = generateAlternateEulerAngles(eul, seq)
%This function is for internal use only. It may be removed in the future.

% GENERATEALTERNATEEULERANGLES Convert euler angles to alternative
% representation

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

eulAltUnwrapped = eul;
eulAltUnwrapped(:,2) = -eulAltUnwrapped(:,2);
eulAltUnwrapped = eulAltUnwrapped + pi;

if any(strcmp(seq, {'ZYZ', 'ZXZ', 'YZY', 'XYX', 'XZX', 'YXY'}))
    eulAltUnwrapped(:,2) = eulAltUnwrapped(:,2) - pi;
end

eulAlt = robotics.internal.wrapToPi(eulAltUnwrapped);

end
