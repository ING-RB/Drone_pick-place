function failures = preValidateTask(task)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022-2023 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.Task
end

failures = validateInputs(task.inputList());
end

function failures = validateInputs(inputList)
import matlab.buildtool.validations.ValidationFailure;

failures = ValidationFailure.empty(1,0);
for input = inputList
    if input.Dynamic
        propName = "Inputs";
    else
        propName = input.Name;
    end
    if isa(input.Value, "matlab.buildtool.io.FileCollection")
        failures = [failures validateFiles(propName, input.Value)]; %#ok<AGROW>
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