classdef (Hidden) TaskActionFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements struct {mustHaveField(Elements,["ImplementationHash","Workspace"])} = struct("ImplementationHash",{},"Workspace",{})
    end

    methods (Access = ?matlab.buildtool.fingerprints.TaskActionFingerprinter)
        function print = TaskActionFingerprint(elements)
            print.Elements = elements;
        end
    end
end

function mustHaveField(varargin)
matlab.buildtool.internal.mustHaveField(varargin{:});
end
