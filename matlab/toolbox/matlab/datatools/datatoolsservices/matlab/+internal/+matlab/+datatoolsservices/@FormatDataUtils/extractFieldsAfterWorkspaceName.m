% This function extracts the fields that comes after the first
% occurrence of workspaceName followed by a period, i.e. 'who.'
% For example, for 'who.a.b' and 'who.who.a', it returns 'a.b' and 'who.a'
% respectively

% Copyright 2023 The MathWorks, Inc.
function fieldsAfterWorkspaceName = extractFieldsAfterWorkspaceName(selectedFields)
    fieldsAfterWorkspaceName = extractAfter(selectedFields, internal.matlab.datatoolsservices.FormatDataUtils.WORKSPACE_NAME);
end