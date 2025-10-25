function str = createPassFailStatementString(requirementStr,isSatisfied,diagSense)
% This function is undocumented and may change in a future release.

%  Copyright 2017 The MathWorks, Inc.
import matlab.unittest.internal.diagnostics.DiagnosticSense;
import matlab.unittest.internal.diagnostics.MessageString;

if nargin > 2 && diagSense == DiagnosticSense.Negative
    if isSatisfied
        msgKey = 'NegatedRequirementCompletelySatisfied';
    else
        msgKey = 'NegatedRequirementNotCompletelySatisfied';
    end
else % diagSense == DiagnosticSense.Positive
    if isSatisfied
        msgKey = 'RequirementCompletelySatisfied';
    else
        msgKey = 'RequirementNotCompletelySatisfied';
    end
end

str = MessageString(['MATLAB:unittest:ConstraintDiagnosticFactory:' msgKey],...
    requirementStr);
end