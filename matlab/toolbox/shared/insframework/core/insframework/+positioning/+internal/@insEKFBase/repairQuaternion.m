function state = repairQuaternion(filt, state)
%   This function is for internal use only. It may be removed in the future. 
%REPAIRQUATERNION Force orientation quaternion to be positive.

%   Copyright 2021 The MathWorks, Inc.

%#codegen   

if filt.AlwaysRepairQuaternion
    idx = stateinfo(filt, 'Orientation');
    qcompact = state(idx);
    % Invert if the real part is negative
    if qcompact(1) < 0
        qpos = -qcompact;
    else
        qpos = qcompact;
    end

    % For speed, normalize without creating a quaternion object.
    n = norm(qpos);
    qfix = qpos./n;

    state(idx) = qfix;


end

