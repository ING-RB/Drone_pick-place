function count = getOutputCount(sig, opts)
% GETOUTPUTCOUNT Return the number of output arguments for a given CallSignature.
% It is method of matlab.internal.metadata.CallSignature.
%
% getOutputCount(S) returns the number of output arguments of a given
% CallSignature.
%
% getOutputCount(S, Presence=PresenceAttributes) returns the number of
% output arguments that have any of the specified presence attributes
% specified in % the PresenceAttributes. Valid presence attributes include
%     "unspecified", "required", "optional". 
% 
% getOutputCount(S, Kind=KindAttributes) returns the number of output
% arguments that have any of the specified kind attributes in specified in
% the KindAttributes. % Valid kind attributes include
%     "positional", "repeating", "namevalue". 
% 
% getOutputCount(S, Presence=PresenceAttributes, Kind=KindAttributes)
% returns the number of output arguments that share both the presence and
% kind attributes.
%
%   See also: MATLAB.INTERNAL.METADATA.CALLSIGNATURE/GETOUTPUTS

% Copyright 2022 The MathWorks, Inc.
        arguments(Input)
            sig (1,1) matlab.internal.metadata.CallSignature
            opts.Presence (1,1) matlab.internal.metadata.ArgumentPresence
            opts.Kind (1,1) matlab.internal.metadata.ArgumentKind
        end
        arguments(Output)
            count (1,1) uint64
        end
    
        nv = namedargs2cell(opts);
        count = numel(getOutputs(sig, nv{:}));
    end