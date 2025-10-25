function [nms_name,field_name] = splitNamespaceFieldName(merged_name)
%SPLITNAMESPACEFIELDNAME splits the tag name into namespace and field name
%   [NMS_NAME, FIELD_NAME] = SPLITNAMESPACEFIELDNAME(MERGED_NAME) returns
%   2 strings: 1) the namespace and 2) the field name. In the XMP packet,
%   the tag names are stored in the form '<namespace name>:<field name>'.
%   This function splits it to separate the namespace name from the field
%   name.

%   Copyright 2022 The MathWorks, Inc.

    fl_index = strfind(merged_name,':');

    nms_name = merged_name(1:(fl_index-1));
    field_name = merged_name((fl_index+1):end);

    % Converting to valid variable names in MATLAB if they are non-empty
    % If not, return the empty char arrays
    if ~isempty(nms_name)
        nms_name = matlab.lang.makeValidName(nms_name);
    end
    if ~isempty(field_name)
        field_name = matlab.lang.makeValidName (field_name);
    end

end
