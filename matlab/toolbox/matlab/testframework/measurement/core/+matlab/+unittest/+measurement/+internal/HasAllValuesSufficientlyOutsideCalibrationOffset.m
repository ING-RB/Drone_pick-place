classdef HasAllValuesSufficientlyOutsideCalibrationOffset < matlab.unittest.constraints.Constraint
    % This class is undocumented and will change in a future release.
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties(Constant)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:measurement:MeasurementPlugin');
    end
    
    methods
        function tf = satisfiedBy(~, result)
            tf = all(measurementsSufficientlyOutsidePrecision(result));
        end
        
        function diag = getDiagnosticFor(constraint, result)
            import matlab.unittest.diagnostics.StringDiagnostic;
            [passed,labels] = measurementsSufficientlyOutsidePrecision(result);
            if all(passed)
                diag = StringDiagnostic(...
                    constraint.Catalog.getString('SufficientlyOutsidePrecision', ...
                    result.MeasuredVariableName, result.Name));
            else
                failedLabels = unique(labels(~passed));
                messages = cellfun(@(labelStr) constraint.Catalog.getString('InsufficientlyOutsidePrecision', ...
                        result.MeasuredVariableName, appendLabels(result.Name, labelStr)),failedLabels,'UniformOutput',false);
                message = strjoin(messages,[newline newline]);
                diag = StringDiagnostic(message);
            end
        end
    end
end

function [passed, labels] = measurementsSufficientlyOutsidePrecision(result)
tare = result.CalibrationValue;
measurements = result.InternalTestActivity.Measurement;
objectives = result.InternalTestActivity.Objective;
labels = result.InternalTestActivity.Label;
N = length(measurements);
passed = true(1,N);

for i = 1:N
    if (objectives(i) == "estimation")
        passed(i) = true;
    else
        passed(i) = measurements(i).isOutsidePrecision(tare);
    end
end
end

function name = appendLabels(basename,label)
name = basename;
if ~startsWith(label,'_')
    name = [name,' <',label,'>'];
end
end