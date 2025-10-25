function outputs = getOutputs(sig, opts)
% GETINPUTS Return a list of output arguments in the order declared on the
% function line. It is method of matlab.internal.metadata.CallSignature.
%
% getOutputs(S) returns all output arguments of a given CallSignature.
%
% getOutputs(S, Presence=PresenceAttributes) returns output arguments that
% have any of the specified presence attributes specified in the
% PresenceAttributes. Valid presence attributes include
%     "unspecified", "required", "optional". 
% 
% getOutputs(S, Kind=KindAttributes) returns output arguments that have any
% of the specified kind attributes in specified in the KindAttributes.
% Valid kind attributes include
%     "positional", "repeating", "namevalue". 
% 
% getOutputs(S, Presence=PresenceAttributes, Kind=KindAttributes) returns
% output arguments that share both the presence and kind attributes.

% Copyright 2022 The MathWorks, Inc.
    arguments(Input)
        sig (1,1) matlab.internal.metadata.CallSignature
        opts.Presence (1,:) matlab.internal.metadata.ArgumentPresence
        opts.Kind (1,:) matlab.internal.metadata.ArgumentKind
    end
    arguments(Output)
        outputs (1,:) matlab.internal.metadata.Argument
    end

    outputs = sig.Outputs;
    
    if isfield(opts, "Presence") && ~isempty(opts.Presence)
        outputs = outputs(ismember([outputs.Presence], opts.Presence));
    end

    if isfield(opts, "Kind") && ~isempty(opts.Kind)
        outputs = outputs(ismember([outputs.Kind], opts.Kind));
    end
end