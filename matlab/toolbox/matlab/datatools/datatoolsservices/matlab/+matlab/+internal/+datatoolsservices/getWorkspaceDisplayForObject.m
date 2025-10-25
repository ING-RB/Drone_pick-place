% This function is unsupported and might change or be removed without notice in
% a future version.
%
% This function provides a display of an object or a struct, similar to the
% Workspace Browser.
%
% Additional arguments can be the columns to display.  If not specified, the
% default set of columns will be returned, which is:
% name, size, class, value
%
% Columns can be any one of the following:
% name, size, class, value, min, max, mean, median, mode, range, std, var
%
% The return value is a structure array, with each struct containing the fields
% for the selected columns.

% Copyright 2020 The MathWorks, Inc.

function s = getWorkspaceDisplayForObject(obj, varargin)
    import matlab.internal.datatoolsservices.getWorkspaceDisplay;

    % Traverse the properties, creating cell array of the property names and
    % values
    if isstruct(obj)
        propNames = string(fieldnames(obj));
    else
        propNames = string(properties(obj));
    end
    props = cell(length(propNames), 1);
    for idx = 1:length(propNames)
        propName = propNames{idx};
        props{idx} = obj.(propName);
    end
    
    % Call getWorkspaceDisplay, passing through the varargin to it
    s = getWorkspaceDisplay(props, varargin{:});
    
    % Assign the varible names back into the results
    if ~isempty(s)
        t = struct2table(s);
        t.Name = propNames;
        s = table2struct(t);
    end
end
