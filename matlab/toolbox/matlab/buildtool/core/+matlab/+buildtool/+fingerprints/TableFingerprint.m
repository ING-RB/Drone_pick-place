classdef (Hidden) TableFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements table
    end

    methods (Access = ?matlab.buildtool.fingerprints.TableFingerprinter)
        function print = TableFingerprint(elements)
            print.Elements = elements;
        end
    end
end