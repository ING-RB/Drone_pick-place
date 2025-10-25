function tf = issortedrows(T,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

[vars,varData,sortMode,nvPairs] = sortrowsFlagChecks(true,T,varargin{:});

if isempty(vars)
    % Ensure consistency with sortrows(T,[],...) not sorting and returning
    % T, i.e., issortedrows(sortrows(T,[],...),[],...) returns true.
    tf = true;
    return
end

% Prepare the data for the sort check:
hasMultiColumnVars = false;
for jj = 1:numel(vars)
    V = varData{jj};
    % Same errors as in tabular.sortrows
    if ~ismatrix(V)
        error(message('MATLAB:table:issortedrows:NDVar',T.varDim.labels{vars(jj)}));
    elseif istabular(V)
        % Error gracefully when trying to sort tables of tables
        error(message('MATLAB:table:issortedrows:IssortedOnVarFailed',T.varDim.labels{vars(jj)},class(V)));
    end
    % Convert row labels to string because of no issortedrows support for cellstr.
    % No <missing> string here, because row labels cannot be empty ''.
    if iscellstr(V) %#ok<ISCLSTR>
        if vars(jj) == 0
            varData{jj} = string(V);
        else
            error(message('MATLAB:table:issortedrows:CellstrVar',T.varDim.labels{vars(jj)}));
        end
    end
    hasMultiColumnVars = hasMultiColumnVars | (size(V,2) > 1);
end
if hasMultiColumnVars
    % Convert multi-column variables into separate columns to facilitate
    % tiebreak behavior for duplicate missing rows in matrix variables:
    varsOld     = vars;
    varDataOld  = varData;
    sortModeOld = sortMode;
    thisjj = 1;
    for jj = 1:numel(varsOld)
        V = varDataOld{jj};
        [mV,nV] = size(V);
        vars(thisjj:(thisjj+nV-1))     = varsOld(jj);
        varData(thisjj:(thisjj+nV-1))  = mat2cell(V,mV,ones(1,nV));
        sortMode(thisjj:(thisjj+nV-1)) = sortModeOld(jj);
        thisjj = thisjj+nV;
    end
end

% Perform issortedrows check starting with the first specified table
% variable and moving on to the next one if ties are present:
[tf,failInfo] = matlab.internal.math.issortedrowsFrontToBack(varData,sortMode,nvPairs{:});

% Throw helpful error message for unsupported table variables:
if ~isempty(failInfo)
    jj = failInfo.colNum;
    if vars(jj) == 0
        m = message('MATLAB:table:issortedrows:IssortedOnRowFailed');
    else
        m = message('MATLAB:table:issortedrows:IssortedOnVarFailed',T.varDim.labels{vars(jj)},class(varData{jj}));
    end
    throw(addCause(MException(m),failInfo.ME));
end
