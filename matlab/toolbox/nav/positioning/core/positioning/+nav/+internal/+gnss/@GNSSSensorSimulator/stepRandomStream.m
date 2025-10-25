function noise = stepRandomStream(obj, numSamples, numChans)
%STEPRANDOMSTREAM Noise (random noise generation for
%   nav.internal.gnss.GNSSSensorSimulator object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

if strcmp(obj.RandomStream, 'Global stream')
    noise = randn(numSamples, numChans, 'like', obj.pInputPrototype);
else
    noise = randn(obj.pStream, numSamples, numChans, ...
        class(obj.pInputPrototype));
end
end
