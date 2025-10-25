classdef (Hidden) ArrayFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = true;
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.ArrayFingerprinter %#ok<INUSA>
                allPrinters matlab.buildtool.fingerprints.Fingerprinter %#ok<INUSA>
                array
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext %#ok<INUSA>
            end

            import matlab.internal.crypto.BasicDigester;
            import matlab.buildtool.internal.fingerprints.classHash;
            import matlab.buildtool.internal.fingerprints.serializableArrayHash;
            import matlab.buildtool.fingerprints.ArrayFingerprint;
            
            mc = metaclass(array);
            if ~isempty(mc)
                implementationHash = classHash(mc);
            else
                digester = BasicDigester("Blake-2b");
                implementationHash = digester.computeDigest(class(array));
            end
            serializedBytesHash = serializableArrayHash(array);
            
            print = ArrayFingerprint(implementationHash, serializedBytesHash);
        end
    end
end
