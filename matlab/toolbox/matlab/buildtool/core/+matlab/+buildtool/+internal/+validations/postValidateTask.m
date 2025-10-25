function failures = postValidateTask(task)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022-2023 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.Task
end

failures = validateOutputs(task.outputList());
end

function failures = validateOutputs(outputList)
import matlab.buildtool.validations.ValidationFailure;

failures = ValidationFailure.empty(1,0);
for output = outputList
    if output.Dynamic
        propName = "Outputs";
    else
        propName = output.Name;
    end
    if isa(output.Value, "matlab.buildtool.io.FileCollection")
        failures = [failures validateFiles(propName, output.Value)]; %#ok<AGROW>
    end
end
end

function failures = validateFiles(propName, files)
import matlab.buildtool.validations.ValidationFailure;
import matlab.buildtool.validations.ValidationLocation;
import matlab.buildtool.validations.ValidationLocationType;
import matlab.buildtool.internal.validations.FileCollectionValidator;

validator = FileCollectionValidator();

failures = ValidationFailure.empty(1,0);
for file = files(:)'
    message = validator.validate(file);
    if ~isempty(message)
        location = ValidationLocation(propName, ValidationLocationType.Property);
        failures(end+1) = ValidationFailure(location, message); %#ok<AGROW>
    end
end
end