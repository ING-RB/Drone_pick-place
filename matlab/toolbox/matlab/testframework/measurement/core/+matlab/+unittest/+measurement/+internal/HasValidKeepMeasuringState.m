classdef HasValidKeepMeasuringState < matlab.unittest.constraints.Constraint
    % This class is undocumented and will change in a future release.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(SetAccess = private)
        TestName
    end
    
    methods
        function constraint = HasValidKeepMeasuringState(name)
            constraint.TestName = name;
        end
        function tf = satisfiedBy(~, meter)
            tf = meter.hasValidKeepMeasuringState;
        end
        function diag = getDiagnosticFor(constraint, meter)
            diag = meter.getKeepMeasuringDiagnostic(constraint.TestName);
        end
    end
end

