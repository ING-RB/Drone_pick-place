function validateStructAgainstTemplate(inputStruct, templateStruct, funcName, varName)
%This function is for internal use only. It may be removed in the future.

%validateStructAgainstTemplate Verify that input is a struct with the same format as
%the templateStruct

%   Copyright 2018-2023 The MathWorks, Inc.

%#codegen

    if coder.target('MATLAB')
        validateattributes(inputStruct, {'struct'}, {'scalar'}, funcName, varName);

        inputFields = fields(inputStruct);
        templateFields = fields(templateStruct);

        % put the errorIf inside condition to avoid unnecessary
        % call to unrollFieldNames
        if numel(inputFields) ~= numel(templateFields)
            coder.internal.errorIf(true, ...
                                   'shared_robotics:validation:StructFieldMismatch', ...
                                   varName, unrollFieldNames(templateFields));
        end

        for idx = 1:numel(templateFields)
            template = templateStruct.(templateFields{idx});
            if ~strcmp(inputFields{idx}, templateFields{idx})
                coder.internal.errorIf(true, ...
                                       'shared_robotics:validation:StructFieldMismatch', ...
                                       varName, unrollFieldNames(templateFields));
            end
            validateattributes(inputStruct.(templateFields{idx}), ...
                               {class(template)}, {'size', size(template)}, ...
                               funcName, strcat(varName,".",templateFields{idx}));
        end
    end
end



function s = unrollFieldNames(names)
%unrollFieldNames unrolls a cell array of char into the format
%["names{1}", "names{2}", ...]

    s = "[";
    for i = 1:numel(names)-1
        s = strcat(s, '"', names{i}, '", ');
    end
    s = strcat(s, '"', names{end}, '"]');
end
