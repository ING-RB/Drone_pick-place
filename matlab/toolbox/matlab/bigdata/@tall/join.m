function varargout = join(A, varargin)
%JOIN Combine elements of a string array or merge two tables or timetables.
%
%   For tall string arrays:
%
%   S = JOIN(STR)
%   S = JOIN(STR, DELIMITER)
%   S = JOIN(STR, DIM)
%   S = JOIN(STR, DELIMITER, DIM)
%
%   For tall tables and tall timetables:
%
%   T = JOIN(TLEFT, TRIGHT) 
%   T = JOIN(TLEFT, TRIGHT, 'PARAM1',val1, 'PARAM2',val2, ...)
%   [T, IRIGHT] = JOIN(...)
%
%   Limitation for tall tables and tall timetables:
%   To join a timetable and a table, you must specify the timetable as
%   the first JOIN input. 
%
%   See also TALL/STRING, TABLE/JOIN, TIMETABLE/JOIN,
%            TALL/INNERJOIN, TALL/OUTERJOIN

%   Copyright 2016-2024 The MathWorks, Inc.

% First input should be 'string', 'table', or 'timetable'
A = tall.validateType(A, mfilename, {'string' 'table' 'timetable'}, 1);
ca = tall.getClass(A);

if strcmp(ca, 'table') || strcmp(ca, 'timetable')
    narginchk(2,inf);
    B = varargin{1};
    % These next two checkIsTall calls are not strictly needed, but they
    % lead to helpful errors for join(nonTallA,nonTallB,tallOptionalInputs)
    if ~istall(A)
        tall.checkIsTall(upper(mfilename), 2, B);
    end
    if ~istall(B)
        tall.checkIsTall(upper(mfilename), 1, A);
    end
    % No tall optional inputs
    varargin = varargin(2:end);
    tall.checkNotTall(upper(mfilename), 2, varargin{:});
    
    % Match in-memory error messages
    cb = tall.getClass(B);
    if strcmp(ca, 'table')
        if strcmp(cb, 'timetable')
            % Because we can't concatenate tall tables with tall timetables
            error(message('MATLAB:table:join:TableTimetableInput'));
        elseif ~strcmp(cb, 'table')
            error(message('MATLAB:table:join:InvalidInput'));
        end
    else
        if ~strcmp(cb, 'timetable') && ~strcmp(cb, 'table')
            error(message('MATLAB:table:join:InvalidInput'));
        end
    end
    
    % Join tall (time)table with tall or in-memory (time)table
    Aname = inputname(1);
    Bname = inputname(2);
    [varargout{1:nargout}] = iJoinTable(A, Aname, B, Bname, varargin{:});
else
    % String JOIN
    narginchk(1,3);
    tall.checkIsTall(upper(mfilename), 1, A);
    tall.checkNotTall(upper(mfilename), 1, varargin{:});
    [varargout{1:nargout}] = iJoinString(A, varargin{:});
end
end

function s = iJoinString(str, varargin)
% Work out if we know the dimension and delimiter
delim = ' ';
dim = [];
dimSpecified = false;
if nargin>2
    % JOIN(STR, DELIMITER, DIM)
    delim = varargin{1};
    dim = varargin{2};
    dimSpecified = true;
elseif nargin==2
    % JOIN(STR, DELIMITER) or JOIN(STR, DIM)
    if isnumeric(varargin{1})
        dim = varargin{1};
        dimSpecified = true;
    else
        delim = varargin{1};
    end
end


if ~dimSpecified
    % We need to select the last non-singleton dimension. If the dimension
    % cannot be deduced, error.
    dim = iGetLastNonsingletonDim(str);
    if isempty(dim)
        % Could not deduce dimension to us. For now we just error. In
        % future we could run both reduction and slice operations and
        % choose the right result lazily.
        error(message('MATLAB:bigdata:array:JoinNoDim'));
    end
end

% Check that delimiter is size 1 in tall dimension
if size(delim, 1) > 1
    error(message('MATLAB:bigdata:array:JoinDelimHeight'));
end

% Dimension now known. Either work on slices or reduce.
fcn = @(x) join(x,delim,dim);
if isequal(dim, 1) % TallDimension

    % Here we must run the reduction both ignoring empties and not ignoring empties,
    % selecting the result based on whether the overall array is size zero in
    % the tall dimension. We attempt to do the check up-front, but failing that
    % we do the check lazily. Both versions must set the adaptor type
    % correctly to avoid problems in clientfun.

    resultWhenEmptyInTallDim    = reducefun(fcn, str);
    resultWhenEmptyInTallDim.Adaptor = resetTallSize(str.Adaptor);

    resultWhenNotEmptyInTallDim = reducefun(@(x) iLocalJoinString(x, delim, dim), str);
    resultWhenNotEmptyInTallDim.Adaptor = resetTallSize(str.Adaptor);

    if getSizeInDim(str.Adaptor, 1) == 0
        s = resultWhenEmptyInTallDim;
    elseif getSizeInDim(str.Adaptor, 1) > 0
        s = resultWhenNotEmptyInTallDim;
    else
        isEmptyInTallDim = size(str, 1) == 0;
        s = clientfun(@iPickResult, isEmptyInTallDim, ...
                      resultWhenEmptyInTallDim, resultWhenNotEmptyInTallDim);
    end
    s.Adaptor = computeReducedSize(str.Adaptor, str.Adaptor, dim, false);
else
    s = slicefun(fcn, str);
    % Result is same type as STR, but same size as S
    s.Adaptor = copySizeInformation(str.Adaptor, s.Adaptor);
end
end

function out = iPickResult(tf, trueResult, falseResult)
%Used with 'clientfun' to choose between input arguments.
if tf
    out = trueResult;
else
    out = falseResult;
end
end

function out = iLocalJoinString(str, delim, dim)
% A variant of string join that defends against empty partitions. It's only
% valid to use this providing the overall array is non-empty - otherwise, it
% returns the wrong overall result.
if size(str, dim) == 0
    % Return empty rather than <missing>
    out = str;
else
    out = join(str, delim, dim);
end
end

function dim = iGetLastNonsingletonDim(x)
% Try to find the last non-singleton dimension of x. If the dimensions are
% unknown then the result is empty.
dim = [];
if isnan(x.Adaptor.NDims) || any(isnan(x.Adaptor.SmallSizes))
    return;
end

% We know both the number of dimensions and the size in each
% dimension. We pre-pend a zero so that the result is 1 if all other
% dimensions are unity.
dim = find([0, x.Adaptor.SmallSizes] ~= 1, 1, 'last');
end

function [tC,tIR] = iJoinTable(tA, Aname, tB, Bname, varargin)
% JOIN tall (time)table with tall or in-memory (time)table.

% If B is not tall and we don't need a second output, use a fast slicefun.
if istall(tA) && ~istall(tB) && nargout < 2
    % Use joinBySample to create an appropriate adaptor for the output. We
    % do this first as it provides the actual variable names. We don't want
    % to repeat this same work per chunk.
    adaptorA = tA.Adaptor;
    adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(tB);
    requiresVarMerging = true;
    [adaptorOut, varNames] = joinBySample(...
        @(A, B) joinNamedTables(@join, A, B, Aname, Bname, varargin{:}), ...
        requiresVarMerging, adaptorA, adaptorB);

    % Now schedule the actual work.
    tC = slicefun(@(x)iJoinTableBySlice(x,tB,varNames,varargin{:}),tA);
    tC.Adaptor = adaptorOut;
    return
end

% For all other combinations, use the tall-to-tall algorithm.
if ~istall(tA)
    tA = tall.createGathered(tA,getExecutor(tB));
end
if ~istall(tB)
    tB = tall.createGathered(tB,getExecutor(tA));
end
if nargout < 2
    tC = iJoinTwoTallTables(tA,Aname,tB,Bname,varargin{:});
else
    [tC,tIR] = iJoinTwoTallTables(tA,Aname,tB,Bname,varargin{:});
end
end

function C = iJoinTableBySlice(A,B,varNamesOut,varargin)
C = join(A,B,varargin{:});
C.Properties.VariableNames = varNamesOut;
end

function [tC,tIR] = iJoinTwoTallTables(tA,Aname,tB,Bname,varargin)
% JOIN tall (time)table with tall (time)table.

% Create the correct (time)table output adaptor and quickly match in-memory
% error messages for invalid variables specified in 'Keys', 'LeftKeys',
% 'RightKeys', 'LeftVariables', 'RightVariables', and 'KeepOneCopy'.
adaptorA = tA.Adaptor;
adaptorB = tB.Adaptor;
requiresVarMerging = true;
[adaptorOut, varNamesOut] = joinBySample(...
    @(A, B) joinNamedTables(@join, A, B, Aname, Bname, varargin{:}), ...
    requiresVarMerging, adaptorA, adaptorB);

% Get 'LeftKeys', 'RightKeys', 'LeftVariable', and 'RightVariables'.
[leftKeysIndA,rightKeysIndB,leftVarsIndA,rightVarsIndB] = ...
    joinGetKeyVars('join',adaptorA,adaptorB,varargin{:});
nKeys = numel(leftKeysIndA);
nVarsA = numel(leftVarsIndA);
nVarsB = numel(rightVarsIndB);

% Extract key data.
[tKeysA,tKeysB] = joinGetKeyData('join',tA,tB,leftKeysIndA,rightKeysIndB);

% Join A and B by permuting the rows of B and concatenating them into A:
% C = [A(:,leftVars), B(IR,rightVars)]
% NOTE: leftVars may also contain the keys for certain N-V combinations.

% A(:,leftVars) -- this also preserves metadata like VariableContinuity.
subsVarNames = substruct('.','Properties','.','VariableNames');
tC = subselectTabularVars(tA,leftVarsIndA);
tC = subsasgn(tC,subsVarNames,varNamesOut(1:nVarsA));
% B(:,rightVars) -- this also preserves metadata like VariableContinuity.
tFromB = subselectTabularVars(tB,rightVarsIndB);

% B(:,rightVars) rides along with the keys of B to get permuted together.
for k = 1:nKeys
    tFromB = subsasgn(tFromB,substruct('.',nVarsB+k),tKeysB{k});
end

% Simultaneously sort the keys of B and permute B(:,rightVars) accordingly.
if nargout == 2
    [tFromB,tIndB] = sortrows(tFromB,nVarsB + (1:nKeys));
else
    tFromB = sortrows(tFromB,nVarsB + (1:nKeys));
end

% Separate the sorted keys and the permuted tFromB = B(tIndB,rightVars).
for k = 1:nKeys
    tKeysB{k} = subsref(tFromB,substruct('.',nVarsB+k));
end
tFromB = subselectTabularVars(tFromB,1:nVarsB);

if nargout == 2
    % Also compute the row permutation by adding one more table variable.
    % tFromB.(nB+1) = tIndB before indexing tFromB with the keys of A.
    tFromB = subsasgn(tFromB,substruct('.',nVarsB+1),tIndB);
end

% Match as many in-memory error messages as possible.
keysNotFoundError = {'MATLAB:table:join:LeftKeyValueNotFound',...
    'MATLAB:table:join:LeftKeyValuesNotFound'};
indexErrors = {'MissingIdxError',keysNotFoundError{1 + (nKeys ~= 1)},...
    'DuplicateIdxError','MATLAB:table:join:DuplicateRightKeyVarValues'};

% Map sorted keys of B to keys of A and re-permute tFromB accordingly. This
% is the same as tFromB(tKeysA,:) for integer-valued numeric tKeysA and
% tFromB already permuted to match sorted tKeysB. It avoids multiple calls
% to three-output tall/unique to convert non-numeric keys to numeric ids.
tKeysA = table(tKeysA{:}); % Original keys for A.
tKeysB = table(tKeysB{:}); % Sorted keys for B.
tFromB = keyindexslices(tFromB,tKeysB,tKeysA,indexErrors{:});

if nargout == 2
    % Also return the row permutation: tIR = tFromB.(nB+1).
    tIR = subsref(tFromB,substruct('.',nVarsB+1));
    tFromB = subselectTabularVars(tFromB,1:nVarsB);
end

% Also set the correct variable names to avoid name conflicts in horzcat.
tFromB = subsasgn(tFromB,subsVarNames,varNamesOut(nVarsA + (1:nVarsB)));

dimNames = getDimensionNames(adaptorA);

% Finally, concatenate C = [A(:,leftVars), B(IR,rightVars)].
if isempty(leftVarsIndA) && strcmp(adaptorA.Class,'timetable') ...
        && ~strcmp(adaptorB.Class,'timetable')
    % TODO: If we just horzcat when A(:,leftVars) is a timetable with no
    % variables and B is a table, we get a table instead of a timetable.
    tTimeA = subsref(tA,substruct('.',dimNames{1}));
    tC = table2timetable(tFromB,'RowTimes',tTimeA);
elseif (all(leftKeysIndA) || all(rightKeysIndB)) ...
        && strcmp(adaptorA.Class,'timetable') ...
        && strcmp(adaptorB.Class,'timetable')
    % If A and B are timetables and the left or right key is not Time, we cannot
    % directly concatenate because time of A may not match time of B. The
    % same scenario for join(tallTable,tallTimetable) is not an issue
    % because we do not support tall join for table-timetable.
    tFromB = timetable2table(tFromB,'ConvertRowTimes',false);
    tC = [tC, tFromB];
else
    tC = [tC, tFromB];
end
tC = elementfun(@matlab.bigdata.internal.adaptors.fixTabularPropertyMetadata,...
    tC,matlab.bigdata.internal.broadcast(adaptorOut));
tC.Adaptor = adaptorOut;

% HORZCAT and JOIN disagree about which input determines the output
% dimension names, so correct that now. JOIN always uses dimension names
% from the first input.
subsDimNames = substruct('.','Properties','.','DimensionNames');
tC = subsasgn(tC, subsDimNames, dimNames);

end