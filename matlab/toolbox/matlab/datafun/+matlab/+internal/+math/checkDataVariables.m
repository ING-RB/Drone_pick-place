function [vars,A] = checkDataVariables(A,vars,eid,groupDataFlag)
%checkDataVariables Validate DataVariables value
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2016-2022 The MathWorks, Inc.

import matlab.internal.tabular.private.tabularDimension

if nargin < 4
    groupDataFlag = "Data";
end

% Allow grouping on time variable of timetable
if ~strcmpi(groupDataFlag,"Data") && istimetable(A)
    if any(strcmpi(A.Properties.DimensionNames{1},vars))
        A = timetable2table(A);
    end
end

if isa(vars,"function_handle")
    nvars = width(A);
    try
        bData = cell(1,nvars);
        for j = 1:nvars
            bData{j} = vars(A.(j));
        end
    catch ME
        error(message("MATLAB:"+eid+":"+groupDataFlag+"VariablesFunctionHandle"));
    end
    if nvars > 0
        for jvar = 1:nvars
            if ~isscalar(bData{jvar})
                error(message("MATLAB:"+eid+":"+groupDataFlag+"VariablesFunctionHandle"));
            elseif jvar == 1
                uniformClass = class(bData{1});
            elseif ~isa(bData{jvar},uniformClass)
                error(message("MATLAB:"+eid+":"+groupDataFlag+"VariablesFunctionHandle"));
            end
        end
        bData = horzcat(bData{:});
    else
        bData = zeros(1,0);
    end
    vars = find(bData);
else
    try
        vars = subscripts2indices(A,vars,'reference','varDim');
        if nargin < 4 % Not a grouping function
            vars = unique(reshape(vars,1,[]));
        end
    catch ME
        error(message("MATLAB:"+eid+":"+groupDataFlag+"VariablesTableSubscript"));
    end
end

vars = reshape(vars,1,[]);
