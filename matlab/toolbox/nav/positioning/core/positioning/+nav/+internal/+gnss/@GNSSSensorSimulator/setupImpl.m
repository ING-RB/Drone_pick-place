function setupImpl(obj)
%SETUPIMPL Setup nav.internal.gnss.GNSSSensorSimulator object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Store reference frame.
obj.pRefFrame = fusion.internal.frames.ReferenceFrame.getMathObject( ...
    obj.ReferenceFrame);
            
% Setup Random Stream object if required.
if strcmp(obj.RandomStream, 'mt19937ar with seed')
    if isempty(coder.target)
        obj.pStream = RandStream('mt19937ar', 'seed', obj.Seed);
    else
        obj.pStream = coder.internal.RandStream('mt19937ar', 'seed', ...
            obj.Seed);
    end
end
end
