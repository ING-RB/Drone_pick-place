function inputs = getInputs(sig, opts)
% GETINPUTS Return a list of input arguments in the order declared on the
% function line. It is method of matlab.internal.metadata.CallSignature.
%
% getInputs(S) returns all input arguments of a given CallSignature.
%
% getInputs(S, Presence=PresenceAttributes) returns input arguments that
% have any of the specified presence attributes specified in the
% PresenceAttributes. Valid presence attributes include
%     "unspecified", "required", "optional". 
% 
% getInputs(S, Kind=KindAttributes) returns input arguments that have any
% of the specified kind attributes in specified in the KindAttributes.
% Valid kind attributes include
%     "positional", "repeating", "namevalue". 
% 
% getInputs(S, Presence=PresenceAttributes, Kind=KindAttributes) returns
% input arguments that share both the presence and kind attributes.

% Copyright 2022 The MathWorks, Inc.
    arguments(Input)
        sig (1,1) matlab.internal.metadata.CallSignature
        opts.Presence (1,:) matlab.internal.metadata.ArgumentPresence
        opts.Kind (1,:) matlab.internal.metadata.ArgumentKind
    end
    arguments(Output)
        inputs (1,:) matlab.internal.metadata.Argument
    end

    inputs = sig.Inputs;

    if isfield(opts, "Presence") && ~isempty(opts.Presence)
        inputs = inputs(ismember([inputs.Presence], opts.Presence));
    end

    if isfield(opts, "Kind") && ~isempty(opts.Kind)
        inputs = inputs(ismember([inputs.Kind], opts.Kind));
    end
end