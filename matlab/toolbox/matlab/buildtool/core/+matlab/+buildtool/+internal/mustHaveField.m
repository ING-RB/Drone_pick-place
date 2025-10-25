function mustHaveField(value, fieldName)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    value
    fieldName string
end

if ~isa(value, "struct")
    throwAsCaller(MException(message("MATLAB:buildtool:Validators:MustBeStruct")));
end

if ~all(isfield(value, fieldName))
    throwAsCaller(MException(message("MATLAB:buildtool:Validators:MustHaveFields", "'"+strjoin(fieldName,"', '")+"'")));
end
end