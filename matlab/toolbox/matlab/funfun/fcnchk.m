function [f,msg] = fcnchk(fun,varargin)
%FCNCHK Check FUNFUN function argument.
%
%   FCNCHK will not accept string expressions for FUN in a future
%   release. Use anonymous functions for FUN instead.
%
%   FCNCHK(FUN,...) returns an inline object based on FUN if FUN
%   is a string containing parentheses, variables, and math
%   operators.  FCNCHK simply returns FUN if FUN is a function handle, 
%   or a MATLAB object with an feval method (such as an inline object). 
%   If FUN is a string name of a function (e.g. 'sin'), FCNCHK returns a
%   function handle to that function.
%
%   FCNCHK is a helper function for FMINBND, FMINSEARCH, FZERO, etc. so they
%   can compute with string expressions in addition to functions.
%
%   FCNCHK(FUN,...,'vectorized') processes the string (e.g., replacing
%   '*' with '.*') to produce a vectorized function.
%
%   When FUN contains an expression then FCNCHK(FUN,...) is the same as
%   INLINE(FUN,...) except that the optional trailing argument 'vectorized'
%   can be used to produce a vectorized function.
%
%   [F,ERR] = FCNCHK(...) returns a struct array ERR. This struct is empty
%   if F was constructed successfully. ERR can be used with ERROR to throw
%   an appropriate error message if F was not constructed successfully.
%
%   See also ERROR, INLINE, @, FUNCTION_HANDLE.

%   Copyright 1984-2024 The MathWorks, Inc.

nin = nargin;
vectorizing = false;
if nin > 1 && strcmp(varargin{end},'vectorized')
    vectorizing = true;
    nin = nin - 1;
end

has_msgident = false;
fun = convertStringsToChars(fun);
if ischar(fun)
    fun = strtrim_local_function(fun);
    % Check for non-alphanumeric characters that must be part of an
    % expression.
    if isempty(fun)
        f = inline('[]'); %#ok<DINLN> 
    elseif ~vectorizing && isidentifier_local_function(fun)
        f = str2func(fun); % Must be a function name only
        % Note that we avoid collision of f = str2func(fun) with any local
        % function named fun, by uglifying the local function's name
        if isequal('x',fun)
            warning(message('MATLAB:fcnchk:AmbiguousX'));
        end
    else
        if vectorizing
            f = inline(vectorize(fun),varargin{1:nin-1}); %#ok<DINLN> 
            var = argnames(f);
            f = inline([formula(f) '.*ones(size(' var{1} '))'],var{1:end}); %#ok<DINLN> 
        else
            f = inline(fun,varargin{1:nin-1}); %#ok<DINLN> 
        end 
    end
elseif isa(fun,'function_handle') 
    f = fun; 
    % is it a MATLAB object with a feval method?
elseif isobject(fun)
    % delay the methods call unless we know it is an object to avoid
    % runtime error for compiler
    [meths,cellInfo] = methods(fun,'-full');
    if ~isempty(cellInfo)   % if fun is a MATLAB object
        meths = cellInfo(:,3);  % get methods names from cell array
    end
    if any(strmatch('feval',meths)) %#ok<MATCH2>
       if vectorizing && any(strmatch('vectorize',meths)) %#ok<MATCH2>
          f = vectorize(fun);
       else
          f = fun;
       end
    else % no feval method
        f = '';
        msgident = 'MATLAB:fcnchk:objectMissingFevalMethod';
        has_msgident = true;
    end
else
    f = '';
    msgident = 'MATLAB:fcnchk:invalidFunctionSpecifier';
    has_msgident = true;
end

% If no errors and nothing to report then we are done.
if nargout < 2 && ~has_msgident
    return
end

% compute MSG
if ~has_msgident
    msg.message = '';
    msg.identifier = '';
    msg = msg(zeros(0,1)); % make sure msg is the right dimension
else
    msg.identifier = msgident;
    msg.message = getString(message(msg.identifier));
end

if nargout < 2
    if ~isempty(msg)
        error(message(msg.identifier));
    end
end


%------------------------------------------
function s1 = strtrim_local_function(s)
%STRTRIM_LOCAL_FUNCTION Trim spaces from string.
% Note that we avoid collision with f = str2func('strtrim')
% by uglifying the local function's name
s1 = strtrim(s);

%-------------------------------------------
function tf = isidentifier_local_function(str)
% Note that we avoid collision with f = str2func('isidentifier')
% by uglifying the local function's name

tf = false;
if ~isempty(str)
    first = str(1);
    if (isletter(first))
        letters = isletter(str);
        numerals = (48 <= str) & (str <= 57);
        underscore = (95 == str);
        tf = all(letters | numerals | underscore);
    end
end

