classdef (Hidden) TableFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = isa(array, "table") && all(cellfun(@(n)allPrinters.supports(array.(n)),array.Properties.VariableNames), "all");
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.TableFingerprinter %#ok<INUSA>
                allPrinters matlab.buildtool.fingerprints.Fingerprinter
                array table
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end
            
            import matlab.buildtool.fingerprints.Fingerprint;
            import matlab.buildtool.fingerprints.TableFingerprint;

            elements = table();
            for n = string(array.Properties.VariableNames)
                elements.(n) = allPrinters.fingerprint(array.(n), context);
            end

            print = TableFingerprint(elements);
        end
    end
end
