classdef (Hidden) ArrayFingerprint < matlab.buildtool.fingerprints.Fingerprint
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    properties (GetAccess = private, SetAccess = immutable)
        ImplementationHash (1,1) matlab.buildtool.internal.fingerprints.HashCode
        SerializedBytesHash (1,1) matlab.buildtool.internal.fingerprints.HashCode
    end

    methods (Access = ?matlab.buildtool.fingerprints.ArrayFingerprinter)
        function print = ArrayFingerprint(implementationHash, serializedBytesHash)
            print.ImplementationHash = implementationHash;
            print.SerializedBytesHash = serializedBytesHash;
        end
    end
end