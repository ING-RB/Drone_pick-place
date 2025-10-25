function c_arrayProps = mergeArrayProps(a_arrayProps,b_arrayProps)  %#codegen
% Use b's per-array property values where a's were empty.

%   Copyright 2019 The MathWorks, Inc.

if isempty(a_arrayProps.Description) && ~isempty(b_arrayProps.Description)
    c_arrayProps.Description = b_arrayProps.Description;
else
    c_arrayProps.Description = a_arrayProps.Description;
end
if isempty(a_arrayProps.UserData) && ~isempty(b_arrayProps.UserData)
    c_arrayProps.UserData = b_arrayProps.UserData;
else
    c_arrayProps.UserData = a_arrayProps.UserData;
end
end
