function [varargout] = parseArgsTabularConstructors(pnames,dflts,priority,StringParamNameNotSupportedErrID,varargin)
%PARSEARGSTABULARCONSTRUCTORS Process parameter name/value pairs for table/timetable constructors
%   [A,B,...] = PARSEARGSTABULARCONSTRUCTORS(PNAMES,DFLTS,PRIORITY,ERRID,'NAME1',VAL1,'NAME2',VAL2,...)
%   In typical use there are N output values, where PNAMES is a cell array of N
%   valid parameter names, DFLTS is a cell array of N default values for these
%   parameters, and PRIORITY is a vector of N integer priorities. The remaining
%   arguments are parameter name/value pairs that were passed into the caller.
%   The N outputs [A,B,...] are assigned in the same order as the names in
%   PNAMES. Outputs corresponding to entries in PNAMES that are not specified in
%   the name/value pairs are set to the corresponding value from DFLTS.
%   Unrecognized name/value pairs are an error.
%
%   PRIORITY is used for backwards compatibility to resolve ambiguous partial
%   parameter name matches. Normally, PRIORITY is a vector of zeros. However, a
%   caller may need to add a new parameter that creates the potential for a
%   partial match against multiple parameter names. In that case, set PRIORITY
%   to 1 for the existing parameter, and to 0 for the new parameter.
%   PARSEARGSTABULARCONSTRUCTORS will resolve a partial match in favor of the
%   existing parameter, preserving behavior of existing code that relied on
%   artial matching. When adding two new parameters that create a partial match
%   ambiguity among themselves, best practice would be to set their priority to
%   zero to force a caller to specify parameter names unambiguously.
%
%   ERRID is the caller-specific matlab:***:StringParamNameNotSupported error ID
%   to be thrown when a string param name is found.
%
%   [A,B,...,SETFLAG] = PARSEARGSTABULARCONSTRUCTORS(...), where SETFLAG is the
%   N+1 output argument, also returns a structure with a field for each
%   parameter name. The value of the field indicates whether that parameter was
%   specified in the name/value pairs (true) or taken from the defaults (false).
%
%   Example:
%      args = {'Var' {'x' 'y'} 'Row' };
%      pnames = {'Size' 'VariableTypes' 'VariableNames'  'RowNames' };
%      dflts =  {    []              {}              {}          {} };
%      partialMatchPriority = [0 0 1 0]; % prioritize VariableNames when partial matching, for backwards compatibility
%      [sz, vartypes, varnames,rownames,supplied] ...
%          = parseArgsTabularConstructors(pnames, dflts, partialMatchPriority, args{:});
%      % On return, sz==[], vartypes=={}, varnames=={'x' 'y'}, rownames=={'a' 'b' 'c'},
%      % supplied.VariableNames=true, and all other fields in supplied are set to false.

%   Copyright 2018-2019 The MathWorks, Inc.

% Initialize some variables
nparams = length(pnames);
varargout = dflts;
setflag = false(1,nparams);
nargs = length(varargin);

SuppliedRequested = nargout > nparams;

% Must have name/value pairs
if mod(nargs,2)~=0
    % This may have been caused by a char row intended as data. The caller can
    % make a suggestion.
    throwAsCaller(MException(message('MATLAB:table:parseArgs:WrongNumberArgs')));
end

% Process name/value pairs
for j=1:2:nargs
    pname = varargin{j};
    if ischar(pname) && isrow(pname) && (numel(pname) > 0) % don't match ''
        % OK
    elseif isstring(pname) && isscalar(pname) && ~ismissing(pname)
        throwAsCaller(MException(message(StringParamNameNotSupportedErrID,pname)));
    else
        throwAsCaller(MException(message('MATLAB:table:parseArgs:IllegalParamName')));
    end

    mask = startsWith(pnames,pname,'IgnoreCase',true); % look for partial match
    if ~any(mask)
        if j == 1
            % If the unrecognized char row was the first thing, it may have
            % been intended as data. Throw a more specific error to let the
            % caller recognize this case and make a suggestion.
            ME = MException(message('MATLAB:table:parseArgs:BadParamNamePossibleCharRowData',pname));
        else
            ME = MException(message('MATLAB:table:parseArgs:BadParamName',pname));
        end
        throwAsCaller(ME);
    elseif sum(mask) > 1
        % Ambiguous partial match, check the priorities of the matches
        matchPriority = priority(mask);
        maxPriority = max(matchPriority);
        if sum(matchPriority == maxPriority) > 1
            % Multiple matches all have the highest priority, throw an error
            throwAsCaller(MException(message('MATLAB:table:parseArgs:AmbiguousParamName',pname)));
        else
            % One of the partial matches has the unique highest priority,
            % solving the ambiguity. Remove the other partial matches.
            mask(mask & (priority ~= maxPriority)) = 0;
        end
    end
    varargout{mask} = varargin{j+1};
    setflag(mask) = true;
end

% Return extra stuff if requested
if SuppliedRequested
    for kk = 1:numel(pnames)
        supplied.(pnames{kk}) = setflag(kk);
    end
    varargout{nparams+1} = supplied;
end
