classdef (Hidden) StructFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements struct
    end

    methods (Access = ?matlab.buildtool.fingerprints.StructFingerprinter)
        function print = StructFingerprint(elements)
            print.Elements = elements;
        end
    end
end