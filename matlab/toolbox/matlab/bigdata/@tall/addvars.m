function b = addvars(a, varargin)
%ADDVARS Add variables to tall table or timetable.
%   T2 = ADDVARS(T1, VAR1, ..., VARN)
%   T2 = ADDVARS(..., 'Before', LOCATION) 
%   T2 = ADDVARS(..., 'After',  LOCATION)
%   T2 = ADDVARS(..., 'NewVariableNames', NEWNAMES)
%
%   See also TABLE, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% Make sure that the first input is a tall table/timetable.
thisFcn = upper(mfilename);
tall.checkIsTall(thisFcn, 1, a);
a = tall.validateType(a, thisFcn, {'table', 'timetable'}, 1);

% Make sure that the new variables to add are tall array/table/timetable
numNewVars = matlab.bigdata.internal.util.countTableVarInputs(varargin);
for ii = 1:numNewVars
    tall.checkIsTall(thisFcn, 1+ii, varargin{ii});
end

% Parse name-value pairs provided as name=value syntax. Name coming from
% Name=Value would be a scalar string. Convert it to char row vector,
% because tabular constructors don't allow scalar strings for name-value
% names.
import matlab.lang.internal.countNamedArguments
% Check if name=value syntax has been used, it must be done in the function
% called by the user.
try
    numNamedArguments = countNamedArguments();
catch
    % If countNamedArguments fails, no name-value pairs have been provided
    % with name=value syntax.
    numNamedArguments = 0;
end
args = matlab.bigdata.internal.util.parseNamedArguments(numNamedArguments, varargin{numNewVars+1:end});
[varargin{numNewVars+1:end}] = args{:};

% Use the in-memory version to do input checking
bProto = tall.validateSyntax(@addvars, [{a},varargin], 'DefaultType', 'double');

% Extract tall new variables and optional name-value pairs
newVars = varargin(1:numNewVars);
[varargin(1:numNewVars)] = [];
optArgs = varargin;

% Check if NewVariableNames name-value pair has been provided
newVarNamesProvided = false;
for ii = 1:numel(optArgs)
    in = optArgs{ii};
    isStringInput = matlab.internal.datatypes.isScalarText(in);
    if isStringInput && any(startsWith('NewVariableNames', in, 'IgnoreCase', true))
        newVarNamesProvided = true;
    end
end

% If the variable names were automatically determined, we may need to use
% inputname to rename them.
if ~newVarNamesProvided
    oldVarNames = a.Adaptor.getVariableNames();
    allVarNames = bProto.Properties.VariableNames;
    [newVarNames, newIdx] = setdiff(allVarNames, oldVarNames, "stable");
    for ii=1:numNewVars
        inName = inputname(ii+1);
        if ~isempty(inName)
            newVarNames{ii} = inName;
        end
    end
    % Make sure the new names don't conflict with existing variables names.
    newVarNames = matlab.lang.makeUniqueStrings(newVarNames, oldVarNames, namelengthmax);
    % Update name-value pairs
    optArgs = [optArgs{:}, {'NewVariableNames'}, {newVarNames}];
    % Update bProto to get the adaptor with the updated new variable names.
    bProto.Properties.VariableNames(newIdx) = newVarNames;
end

% Use slicefun to call in-memory addvars
b = slicefun(@(a, varargin) addvars(a, varargin{:}, optArgs{:}), a, newVars{:});

% Update the adaptor for b with the prototype from tall/validateSyntax
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(bProto);
b.Adaptor = resetTallSize(adaptorB);
end