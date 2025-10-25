function t = renamevars(t, vars, newNames)
%RENAMEVARS Rename variables in a tall table or timetable
%   T1 = RENAMEVARS(T1,VARS,NEWNAMES)
%   T2 = RENAMEVARS(T1,VARS,NEWNAMES)
%
%   See also TABLE, TALL, RENAMEVARS.

%   Copyright 2019 The MathWorks, Inc.

if nargout == 0
    error(message("MATLAB:table:renamevars:NoLHS"));
end
narginchk(3, 3);

% Validate T, it must be a tall table or timetable
thisFcn = upper(mfilename);
tall.checkIsTall(thisFcn, 1, t);
t = tall.validateType(t, thisFcn, ["table", "timetable"], 1);

% vars and newnames must not be tall
tall.checkNotTall(thisFcn, 1, vars, newNames);

% VARS is a positive integer, a vector of positive integers, a variable
% name, a string array or cell array containing one or more variable names,
% a logical vector, or a vartype subscripter. Resolve name subscripts or
% vartype inputs into numeric/logical indices.
adaptorT = matlab.bigdata.internal.adaptors.getAdaptor(t);
if isa(vars, "vartype")
    idx = isaVariableOfType(adaptorT, vars);
else
    % Text, numeric or logical
    if ~any([matlab.internal.datatypes.isText(vars), islogical(vars), isnumeric(vars)])
        error(message("MATLAB:table:renamevars:InvalidVarSubscript"));
    end
    
    % Renaming dimension names is not allowed.
    dimNames = getDimensionNames(adaptorT);
    if matlab.internal.datatypes.isScalarText(vars) && any(matches(vars, dimNames))
        error(message("MATLAB:table:renamevars:RenameDim"));
    end
    
    [~, idx] = matlab.bigdata.internal.util.resolveTableVarSubscript( ...
        getVariableNames(adaptorT), vars);
end

% Define substruct to access VariableNames and add numeric subscripts.
S = substruct(".", "Properties", ".", "VariableNames", "()", {idx});

% Validate new variable names and wrap char vectors into cellstr for
% subsasgn.
if ~matlab.internal.datatypes.isText(newNames)
    error(message("MATLAB:table:renamevars:NamesNotText"));
end
if isa(newNames, "char")
    newNames = {newNames};
end

% Call subsasgn to do the actual work
try
    t = subsasgn(t, S, newNames);
catch err
    varNames = getVariableNames(adaptorT);
    if strcmpi(err.identifier, "MATLAB:matrix:singleSubscriptNumelMismatch") ...
            || (strcmpi(err.identifier, "MATLAB:table:DuplicateVarNames") && ~any(matches(newNames, varNames)))
        err = MException("MATLAB:table:renamevars:NumNamesMismatch", ...
            message("MATLAB:table:renamevars:NumNamesMismatch"));
    end
    throw(err);
end