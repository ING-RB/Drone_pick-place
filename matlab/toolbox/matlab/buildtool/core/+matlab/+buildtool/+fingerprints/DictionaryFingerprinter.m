classdef (Hidden) DictionaryFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = isa(array, "dictionary") && (~array.isConfigured || all(cellfun(@allPrinters.supports,array.values("cell")), "all"));
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.DictionaryFingerprinter %#ok<INUSA>
                allPrinters matlab.buildtool.fingerprints.Fingerprinter
                array dictionary
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.fingerprints.Fingerprint;
            import matlab.buildtool.fingerprints.DictionaryFingerprint;

            elements = dictionary();
            for e = array.entries("struct")'
                elements(e.Key) = allPrinters.fingerprint(e.Value, context);
            end
            
            print = DictionaryFingerprint(elements);
        end
    end
end
