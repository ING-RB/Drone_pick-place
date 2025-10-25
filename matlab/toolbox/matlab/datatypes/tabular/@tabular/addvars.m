function b = addvars(a,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc.
import matlab.internal.datatypes.parseArgsTabularConstructors
import matlab.lang.internal.countNamedArguments
import matlab.lang.internal.move % Avoid unsharing of shared-data copy across function call boundary

a_varDim = a.varDim;

% Get the count of Name=Value arguments in varargin.
try
    numNamedArguments = countNamedArguments();
catch
    % If countNamedArguments fails, revert back to old behavior
    % and assume that none of the NV pairs were passed in as
    % Name=Value.
    numNamedArguments = 0;    
end

[numVars, ~, nvpairs] = tabular.countVarInputs(varargin,'MATLAB:table:addmovevars:StringParamNameNotSupported',numNamedArguments);
numRows = a.rowDim.length; % num rows of the table being added to

if numVars < numel(varargin)
    pnames = {'NewVariableNames'  'Before'           'After' };
    dflts =  {               []        []    a_varDim.length };

    partialMatchPriority = [0 0 0]; % no partial match overlap
    try
        [newvarnames,before,after,supplied] ...
            = parseArgsTabularConstructors(pnames, dflts, partialMatchPriority, ...
                                           'MATLAB:table:addmovevars:StringParamNameNotSupported', ...
                                           nvpairs{:});
    catch ME
        % The inputs included a 1xM char row that was interpreted as the start
        % of param name/value pairs, but something went wrong. If target table
        % has one row, the WrongNumberArgs or BadParamName (when the
        % unrecognized name was first among params) errors suggest that the char
        % row might have been intended as data. Suggest alternative options in
        % that case. Only suggest this alternative if the char row vector did
        % not come from Name=Value.
        errIDs = ["MATLAB:table:parseArgs:WrongNumberArgs" ...
                  "MATLAB:table:parseArgs:BadParamNamePossibleCharRowData"];
        if matches(ME.identifier,errIDs)
            namedArgumentsStart = nargin - 2*numNamedArguments + 1;
            if (numRows == 1) && (namedArgumentsStart > numVars+2)
                pname1 = varargin{numVars+1}; % always the first char row vector
                ME = ME.addCause(MException(message('MATLAB:table:addmovevars:AddingCharRowData',pname1)));
            end
        end
        % 'StringParamNameNotSupported' suggests the opposite, a 1-row string intended as a param.
        throw(ME);
    end
else
    supplied.NewVariableNames = false;
    supplied.Before = false;
    supplied.After = false;
    after = a_varDim.length;
end

if supplied.After && supplied.Before
    error(message('MATLAB:table:addmovevars:BeforeAndAfter'));
end

if supplied.After && isa(after,"pattern") || supplied.Before && isa(before,"pattern")
    error(message('MATLAB:table:addmovevars:InvalidLocation','pattern'));
end

% Figure out the positions of the new variables now so that generated var
% names can be correctly numbered.
% Support edge cases of 'After' 0 and 'Before' width(t)+1 which could be
% hit programmatically with empty tables.
if ~supplied.Before && isnumeric(after) && isscalar(after) && after == 0 % 'After', 0 becomes 'Before', 1
    addIndex = 1;
    supplied.Before = true;
    supplied.After = false;
elseif supplied.Before && isnumeric(before) && isscalar(before) && before == a_varDim.length + 1 
    if a_varDim.length ~= 0 % non-empty table: 'After', width(t)
        addIndex = before - 1;
        supplied.Before = false;
        supplied.After = true;
    else % empty table: 'Before', 1
        addIndex = 1;
    end
else % 
    if supplied.Before
        pos = before;
    else
        pos = after;
    end

    try
        addIndex = a_varDim.subs2inds(pos);
    catch ME
        if isa(pos,'vartype')
            error(message('MATLAB:table:addmovevars:InvalidLocation','vartype subscripter'))
        elseif iscell(pos) % Throw an addvars-specific error for arbitrary cell arrays that error.
            error(message('MATLAB:table:addmovevars:NonscalarPosition'))
        else
            rethrow(ME)
        end
    end
end
% cast other numeric types
addIndex = double(addIndex);

if ~isscalar(addIndex)
    error(message('MATLAB:table:addmovevars:NonscalarPosition'))
end

% Generate default names for the added data var(s) if needed, avoiding conflicts
% with existing var or dim names. If NewVariableNames was given, duplicate names
% are an error, caught by setLabels here or by checkAgainstVarLabels below.
if ~supplied.NewVariableNames
    % Get the workspace names of the input arguments from inputname
    newvarnames = cell(1,numVars);
    for i = 1:numVars, newvarnames{i} = inputname(i+1); end
    % Fill in default names for data args where inputname couldn't.
    empties = cellfun('isempty',newvarnames);
    if any(empties)
        % Adjust names to reflect position - shift to where they're added, shift back one if 'Before'.
        newvarnames(empties) = a_varDim.dfltLabels(find(empties) + addIndex - supplied.Before); 
    end
    % Make sure default names or names from inputname don't conflict with
    % existing variables names.
    newvarnames = matlab.lang.makeUniqueStrings(newvarnames,[a_varDim.labels a.metaDim.labels],namelengthmax);
else % supplied.NewVariableNames
    [tf,newvarnames] = matlab.internal.datatypes.isText(newvarnames);
    if ~tf
        error(message('MATLAB:table:addmovevars:InvalidVarNames'));
    elseif length(newvarnames) ~= numVars
        % Check that there are the right number of supplied varnames.
        error(message('MATLAB:table:addmovevars:IncorrectNumberOfVarNames'));
    end
    % New vars cannot clash with a's dim names. We know they don't if we
    % create them. Only check when user-supplied.
    a.metaDim.checkAgainstVarLabels(newvarnames,'error');

    % New vars cannot clash with a's reserved names. We know they don't if
    % we create them, check only if user-supplied
    a_varDim.checkReservedNames(newvarnames);
end

b = a;
% Adding no variables is a no-op. Do this after going through newvarnames
% to provide a helpful error if numVars differs from number of newvarnames.
if numVars == 0
    return
end

for ii = 1:numVars
    % Check for duplicates before doing assignment, otherwise subsasgnDot will
    % overwrite the existing variable of the same name.
    duplicates = matches(b.varDim.labels,newvarnames{ii});
    if any(duplicates)
        error(message('MATLAB:table:DuplicateVarNames',b.varDim.labels{find(duplicates,1)}))
    end
    % Explicitly call dotAssign to always dispatch to subscripting code, even
    % when the variable name matches an internal tabular property/method.
    b = move(b).dotAssign(newvarnames{ii},varargin{ii}); % b.(newvarnames{ii}) = varargin{ii}
end

if supplied.Before
    b = movevars(b,a_varDim.length + 1:b.varDim.length,'Before',addIndex);
else
    b = movevars(b,a_varDim.length + 1:b.varDim.length,'After',addIndex);
end
