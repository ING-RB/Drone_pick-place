function [hasComplexVariables, complexVariables] = getComplexityInfo(data)
% Check if the data is complex. For tabular types, this will recurse into
% table variables.
%
% This is used by TallDatastore to ensure chunked complex data remains
% complex throughout the entire dataset.

%   Copyright 2017-2019 The MathWorks, Inc.

[hasComplexVariables, complexVariables] = iProcessOneLevel(data);
end


function [isAnyComplex, complexVariables] = iProcessOneLevel(data)
% Helper that can be called recursively to descend a heirarchy of tables.

if isnumeric(data)
    % Data is the variable
    isAnyComplex = ~isreal(data);
    complexVariables = {isAnyComplex};
    
elseif istable(data) || istimetable(data)
    % Return one result per variable
    
    % TODO(g1580766): This is an internal API of table and should be
    % replaced by the official API table2struct(chunk,'ToScalar',true) or a
    % call to AVRFUN. However, both VARFUN and table2struct are at lest 5x
    % slower and this function is used in a performance-critical tight loop.
    vars = getVars(data, false);
    [isAnyComplex, complexVariables] = cellfun(@iProcessOneLevel, vars);
    isAnyComplex = any(isAnyComplex);
    complexVariables = {complexVariables};
   
else
    % Can't be complex
    complexVariables = {false};
    isAnyComplex = false;
end

end