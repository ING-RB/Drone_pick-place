classdef DidNotDetectKeepMeasuringAndLoopedMeasurementTogether < matlab.unittest.constraints.Constraint
    % This class is undocumented and will change in a future release.

    % Copyright 2024 The MathWorks, Inc.

    properties(Constant)
        Catalog = matlab.internal.Catalog("MATLAB:unittest:measurement:MeasurementPlugin");
    end

    properties
        TestName
    end

    methods
        function constraint = DidNotDetectKeepMeasuringAndLoopedMeasurementTogether(name)
            constraint.TestName = name;
        end

        function tf = satisfiedBy(~, plugin)
            tf = ~plugin.KeepMeasuringLoopedMeasurementConflict;
        end

        function diag = getDiagnosticFor(constraint, plugin)
            import matlab.unittest.diagnostics.StringDiagnostic;
            if plugin.KeepMeasuringLoopedMeasurementConflict
                diag = StringDiagnostic(constraint.Catalog.getString("KeepMeasuringLoopedMeasurementConflict", ...
                    constraint.TestName));
            else
                diag = StringDiagnostic(constraint.Catalog.getString("KeepMeasuringLoopedMeasurementNoConflict", ...
                    constraint.TestName));
            end
        end
    end
end