classdef ArgumentTpl
    %ArgumentTpl Holds MATLAB metadata on a MATLAB argument
    
    %   Copyright 2022-2023 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Name  (1,1) string = ""  % variable name of the argument
        InputOrOutput (1,1) string = ""; % input or output argument
        Presence matlab.internal.metadata.ArgumentPresence {mustBeScalarOrEmpty} = matlab.internal.metadata.ArgumentPresence.empty(); % E.g. optional, required, or unspecified. ote: output args are always considered "optional".
        Kind matlab.internal.metadata.ArgumentKind {mustBeScalarOrEmpty} = matlab.internal.metadata.ArgumentKind.empty() % E.g. namevalue, positional, or repeating (varargin/varargout)
        MATLABArrayInfo matlab.engine.internal.codegen.util.MATLABInfo {mustBeScalarOrEmpty} = matlab.engine.internal.codegen.util.MATLABInfo.empty() % Holds type/size data and analysis
    end

    methods
        function obj = ArgumentTpl(arg, inputOrOutput)
            arguments
                arg (1,1) matlab.internal.metadata.Argument
                inputOrOutput (1,1) string {mustBeMember(inputOrOutput, ["input" "output"])}
            end

            % Copy name and category
            obj.Name = string(arg.Name);
            obj.InputOrOutput = inputOrOutput;
            obj.Presence = arg.Presence;
            obj.Kind = arg.Kind;

            % Collate MATLAB Validation data
            obj.MATLABArrayInfo = matlab.engine.internal.codegen.util.MATLABInfo(arg.Validation);

        end

    end
end

