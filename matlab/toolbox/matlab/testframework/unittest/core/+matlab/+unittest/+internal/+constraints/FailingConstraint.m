classdef FailingConstraint < matlab.unittest.constraints.Constraint & ...
                             matlab.unittest.internal.constraints.CasualDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    %FAILINGCONSTRAINT This class is a Constraint to be used in the event of
    %unconditional failure. It is utilized by the <qualify>Fail methods.
    
    % Copyright 2011-2017 The MathWorks, Inc.
    
    methods
        function bool = satisfiedBy(~,~)
            bool = false;
        end
        function diag = getDiagnosticFor(~,~)
            diag = matlab.unittest.diagnostics.Diagnostic.empty(1,0);
        end
    end
    
    methods(Hidden)
        function diag = getCasualDiagnosticFor(varargin)
            diag = matlab.unittest.diagnostics.Diagnostic.empty(1,0);
        end
    end
end