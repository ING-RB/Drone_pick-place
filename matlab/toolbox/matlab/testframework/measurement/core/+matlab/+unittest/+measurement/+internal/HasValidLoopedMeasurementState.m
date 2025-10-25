classdef HasValidLoopedMeasurementState < matlab.unittest.constraints.Constraint
    % This class is undocumented and will change in a future release.
    
    % Copyright 2024 The MathWorks, Inc.
    
    methods
        function tf = satisfiedBy(~, meter)
            tf = meter.hasValidLoopedMeasurementState();
        end
        function diag = getDiagnosticFor(~, meter)
            diag = meter.getLoopedMeasurementDiagnostic();
        end
    end
end