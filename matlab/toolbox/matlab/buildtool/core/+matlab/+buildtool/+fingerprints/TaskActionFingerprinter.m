classdef (Hidden) TaskActionFingerprinter < matlab.buildtool.fingerprints.Fingerprinter
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    methods (Access = protected)
        function tf = supportsArray(printer, allPrinters, array) %#ok<INUSD>
            tf = isa(array, "matlab.buildtool.TaskAction");
        end

        function print = fingerprintArray(printer, allPrinters, array, context)
            arguments
                printer (1,1) matlab.buildtool.fingerprints.TaskActionFingerprinter
                allPrinters matlab.buildtool.fingerprints.Fingerprinter %#ok<INUSA>
                array matlab.buildtool.TaskAction
                context (1,1) matlab.buildtool.fingerprints.FingerprintContext
            end

            import matlab.buildtool.fingerprints.TaskActionFingerprint;

            elements = arrayfun(@(e)printer.fingerprintElement(e,context), array);
            elements = [elements struct("ImplementationHash",{},"Workspace",{})];

            print = TaskActionFingerprint(elements);
        end
    end

    methods (Access = private)
        function print = fingerprintElement(~, action, context)
            import matlab.buildtool.internal.fingerprints.classHash;
            import matlab.buildtool.internal.fingerprints.functionHash;
            import matlab.buildtool.internal.fingerprints.HashCode;
            import matlab.buildtool.fingerprints.ArrayFingerprint;
            import matlab.buildtool.fingerprints.ArrayFingerprinter;

            info = action.info();

            if info.Type == "method"
                implementationHash = classHash(info.DefiningClass);
            else
                implementationHash = functionHash(info.Function, info.Type, info.File);
            end

            if isfield(info, "Workspace")
                workspace = ArrayFingerprinter().fingerprint(info.Workspace, context);
            else
                workspace = ArrayFingerprint.empty();
            end

            print = struct();
            print.ImplementationHash = HashCode(implementationHash);
            print.Workspace = workspace;
        end
    end
end
