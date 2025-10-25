function b = movevars(a, vars, varargin)
%MOVEVARS Move the specified tall table variables to a new location.
%   T2 = MOVEVARS(T1, VARS)
%   T2 = MOVEVARS(T1, VARS, 'Before', LOCATION)
%   T2 = MOVEVARS(T1, VARS, 'After', LOCATION)
%
%   See also TABLE, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% Use the in-memory version to do input checking
bProto = tall.validateSyntax(@movevars, [{a},{vars},varargin], 'DefaultType', 'double');

% Make sure that only the table/timetable input is tall
thisFcn = upper(mfilename);
tall.checkIsTall(thisFcn, 1, a);
tall.checkNotTall(thisFcn, 1, vars, varargin{:});

% If varlist is empty there is nothing to do
if isempty(vars)
    b = a;
    return;
end

% Simply reverse-engineer the new column indices from the prototype
% (variable names are guaranteed unique).
[~,idx] = ismember(bProto.Properties.VariableNames, getVariableNames(a.Adaptor));

% Now let subsref do the actual work since it knows how to copy all the
% table metadata.
b = subselectTabularVars(a, idx);
