classdef (Hidden) CellFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = iscell(array) && all(cellfun(@allPrinters.supports,array), "all");
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.CellFingerprinter %#ok<INUSA>
                allPrinters matlab.buildtool.fingerprints.Fingerprinter
                array cell
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.fingerprints.Fingerprint;
            import matlab.buildtool.fingerprints.CellFingerprint;

            elements = cell(size(array));
            for i = 1:numel(array)
                elements{i} = allPrinters.fingerprint(array{i}, context);
            end
            
            print = CellFingerprint(elements);
        end
    end
end
