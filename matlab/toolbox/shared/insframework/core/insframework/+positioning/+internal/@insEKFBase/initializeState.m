function initializeState(filt)
%INITIALIZESTATE Reset the state vector
%   This method is for internal use only. It may be removed in the future. 

%   Copyright 2021 The MathWorks, Inc.

%#codegen   

opts = filt.Options;

% Initialize state from motion model
motionModelStates = filt.MotionModel.modelstates(opts);
mf = fieldnames(motionModelStates);
for ii=1:numel(mf)
    f = mf{ii};
    idx = stateinfo(filt, f);
    filt.State(idx) = motionModelStates.(f);
end
% Initialize state from sensors
Nsensors = coder.const(numel(filt.Sensors));
coder.unroll;
for ii=1:Nsensors
    sensState = filt.Sensors{ii}.sensorstates(opts);
    sf = fieldnames(sensState);
    coder.unroll;
    for ff=1:numel(sf)
        f = sf{ff};
        idx = stateinfo(filt, filt.Sensors{ii}, f);
        filt.State(idx) = sensState.(f);
    end
end

end