classdef (Hidden) CellFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements cell
    end

    methods (Access = ?matlab.buildtool.fingerprints.CellFingerprinter)
        function print = CellFingerprint(elements)
            print.Elements = elements;
        end
    end
end