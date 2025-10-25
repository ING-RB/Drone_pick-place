classdef (Hidden) StructFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = isstruct(array) && all(arrayfun(@(s)all(structfun(@allPrinters.supports,s)),array), "all");
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.StructFingerprinter %#ok<INUSA>
                allPrinters matlab.buildtool.fingerprints.Fingerprinter
                array struct
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.fingerprints.Fingerprint;
            import matlab.buildtool.fingerprints.StructFingerprint;

            elements = array([]);
            for s = array(:)'
                for n = string(fieldnames(s))'
                    s.(n) = allPrinters.fingerprint(s.(n), context);
                end
                elements = [elements; s]; %#ok<AGROW>
            end
            elements = reshape(elements, size(array));
            
            print = StructFingerprint(elements);
        end
    end
end
