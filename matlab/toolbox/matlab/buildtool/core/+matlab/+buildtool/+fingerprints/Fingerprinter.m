classdef (Hidden, Abstract) Fingerprinter < matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Fingerprinter - Fundamental interface for fingerprinters
    %
    %   The matlab.buildtool.fingerprints.Fingerprinter class specifies how the
    %   build tool should fingerprint a data type.
    %
    %   Fingerprinter methods:
    %      supports    - Determine if fingerprinter supports array
    %      fingerprint - Fingerprint array
    %      default     - Default fingerprinter
    %
    %   See also matlab.buildtool.fingerprints.Fingerprint

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Sealed)
        function tf = supports(printers, array)
            % supports - Determine if fingerprinter supports array
            %
            %   TF = supports(PRINTER,ARRAY) returns logical 1 (true) if PRINTER
            %   supports fingerprinting the specified array, and returns logical 0
            %   (false) otherwise.
            %
            %   Example:
            %
            %      import matlab.buildtool.fingerprints.CellFingerprinter
            %      import matlab.buildtool.fingerprints.FileCollectionFingerprinter
            %      import matlab.buildtool.io.File
            %
            %      fp = CellFingerprinter;
            %      fp.supports(File("f"))   % returns false
            %      fp.supports({})          % returns true
            %      fp.supports({File("f")}) % returns false
            %
            %      fp = [FileCollectionFingerprinter CellFingerprinter];
            %      fp.supports(File("f"))   % returns true
            %      fp.supports({})          % returns true
            %      fp.supports({File("f")}) % returns true

            tf = ~isempty(printers.findFirstFingerprinterFor(array));
        end

        function print = fingerprint(printers, array, context)
            % fingerprint - Fingerprint array
            %
            %   FP = fingerprint(PRINTER,ARRAY) fingerprints the specified array and
            %   returns the fingerprint as a matlab.buildtool.fingerprints.Fingerprint
            %   object. If ARRAY is not supported by PRINTER, the method throws an
            %   error.

            arguments
                printers matlab.buildtool.fingerprints.Fingerprinter
                array
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext = matlab.buildtool.fingerprints.FingerprintContext()
            end

            index = printers.findFirstFingerprinterFor(array);
            if isempty(index)
                throwUnsupportedArray(printers, array);
            end
            print = printers(index).fingerprintArray(printers, array, context);
        end
    end

    methods (Static)
        function printers = default()
            % default - Default fingerprinter
            %
            %   FP = matlab.buildtool.fingerprints.Fingerprinter.default returns a
            %   default row vector of matlab.buildtool.fingerprints.Fingerprint
            %   objects. The default fingerprinter is used when a fingerprinter is
            %   not explicitly specified.

            persistent p;
            if isempty(p)
                p = generateDefaultFingerprinter();
            end
            printers = p;
        end
    end

    methods (Abstract, Access = protected)
        tf = supportsArray(printer, allPrinters, array)
        print = fingerprintArray(printer, allPrinters, array, context)
    end

    methods (Sealed, Access = private)
        function index = findFirstFingerprinterFor(printers, array)
            for index = 1:numel(printers)
                if printers(index).supportsArray(printers, array)
                    return;
                end
            end
            index = [];
        end

        function throwUnsupportedArray(printers, array)
            import matlab.automation.internal.diagnostics.indent;
            import matlab.automation.internal.diagnostics.getDisplayableString;
            arrayString = string(getDisplayableString(array));
            printersString = indent(printers.toDisplayableString());
            error(message("MATLAB:buildtool:Fingerprinter:FingerprintersDoNotSupportArray", ...
                printersString, indent(arrayString)));
        end

        function str = toDisplayableString(printers)
            import matlab.automation.internal.diagnostics.indentWithArrow;
            printerStrings = arrayfun(@(x)indentWithArrow(class(x)), printers, UniformOutput=false);
            str = strjoin(printerStrings, newline());
        end
    end
end

function fp = generateDefaultFingerprinter()
import matlab.buildtool.fingerprints.FileCollectionFingerprinter;
import matlab.buildtool.fingerprints.TaskActionFingerprinter;
import matlab.buildtool.fingerprints.StructFingerprinter;
import matlab.buildtool.fingerprints.CellFingerprinter;
import matlab.buildtool.fingerprints.TableFingerprinter;
import matlab.buildtool.fingerprints.DictionaryFingerprinter;
import matlab.buildtool.fingerprints.ArrayFingerprinter;
fp = [ ...
    FileCollectionFingerprinter, ...
    TaskActionFingerprinter, ...
    StructFingerprinter, ...
    CellFingerprinter, ...
    TableFingerprinter, ...
    DictionaryFingerprinter, ...
    ArrayFingerprinter];
end

% LocalWords:  fingerprinters fingerprinter fp
