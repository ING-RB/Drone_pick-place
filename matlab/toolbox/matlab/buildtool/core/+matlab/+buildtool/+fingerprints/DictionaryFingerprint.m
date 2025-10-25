classdef (Hidden) DictionaryFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        Elements (1,1) dictionary
    end

    methods (Access = ?matlab.buildtool.fingerprints.DictionaryFingerprinter)
        function print = DictionaryFingerprint(elements)
            print.Elements = elements;
        end
    end
end