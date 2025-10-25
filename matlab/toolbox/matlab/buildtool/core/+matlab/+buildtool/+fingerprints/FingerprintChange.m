classdef (Hidden) FingerprintChange < matlab.mixin.Heterogeneous & handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = private, Hidden)
        Type matlab.buildtool.fingerprints.ChangeType {mustBeScalarOrEmpty}
    end

    properties (GetAccess = protected, SetAccess = immutable)
        PreviousFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
        CurrentFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
    end

    properties (Constant, Hidden, Access = protected)
        EmptyDiagnosticArray = matlab.automation.diagnostics.Diagnostic.empty(1,0)
    end

    methods
        function change = FingerprintChange(previousFingerprint, currentFingerprint)
            arguments
                previousFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
                currentFingerprint matlab.buildtool.fingerprints.Fingerprint {atLeastOneMustBeNonEmpty(previousFingerprint,currentFingerprint)}
            end

            change.PreviousFingerprint = previousFingerprint;
            change.CurrentFingerprint = currentFingerprint;
        end

        function t = get.Type(change)
            import matlab.buildtool.fingerprints.ChangeType;

            if isempty(change.Type)
                if isempty(change.PreviousFingerprint)
                    t = ChangeType.Added;
                elseif isempty(change.CurrentFingerprint)
                    t = ChangeType.Removed;
                elseif ~isequal(change.PreviousFingerprint, change.CurrentFingerprint)
                    t = ChangeType.Modified;
                else
                    t = ChangeType.Unmodified;
                end
                change.Type = t;
            end

            t = change.Type;
        end

        function tf = isChanged(change)
            import matlab.buildtool.fingerprints.ChangeType;
            tf = [change.Type] ~= ChangeType.Unmodified;
            tf = reshape(tf, size(change));
        end
    end

    methods (Access = {?matlab.buildtool.fingerprints.FingerprintChange, ?matlab.buildtool.diagnostics.TaskChangeDiagnostic})
        function conds = conditions(change)
            conds = change.EmptyDiagnosticArray;
        end
    end
end

function atLeastOneMustBeNonEmpty(a, b)
if isempty(a)
    mustBeNonempty(b);
end
end