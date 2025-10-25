function [c,i] = max(a,b,varargin) %#codegen
%MAX Largest element in an ordinal categorical array.

%   Copyright 2020-2022 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

% Call processMinMaxOptionalInputs to update the missing flag arguments and
% create a wrapper function handle. See the function for more details.
[omitMissing,maxFun] = processMinMaxOptionalInputs(@max,varargin{:});

% Unary max
if nargin < 2 ... % max(a)
        || (nargin > 2 && isnumeric(b) && isequal(b,[])) % max(a,[],...) but not max(a,[])
    if ~a.isOrdinal
        coder.internal.error('MATLAB:categorical:NotOrdinal');
    end
    
    acodes = a.codes;
    c = a.cloneAsEmpty();
    
    % Missing elements have code zero, less than any legal code. They will not be
    % the max value unless there's nothing else, which is the correct behavior for
    % 'omitmissing'. For 'includemissing', set the code value for missing
    % elements to the largest integer to make sure they will be the max value.
    tmpCode = categorical.invalidCode(acodes);
    if ~omitMissing
        acodes(acodes==categorical.undefCode) = tmpCode;
    end
    
    if nargin < 2
        if nargout <= 1
            ccodes = max(acodes);
        else
            [ccodes,i] = max(acodes);
        end
    else % nargin > 2
        if nargout <= 1
            ccodes = maxFun(acodes,[]);
        else
            [ccodes,i] = maxFun(acodes,[]);
        end
    end
    
% Binary max
else % max(a,b) or max(a,b,...)
    % Accept -Inf as a valid "identity element" in the two-arg case. If compared
    % to <undefined> with 'omitmissing', the minimal value will be the result as
    % long as there is at least one category. If compared with 'includemissing',
    % <undefined> will be the result.
    if isnumeric(a) % && isa(b,'categorical')
        coder.internal.assert(isequal(a,-Inf),'MATLAB:categorical:InvalidComparisonTypes');
        bcodes = b.codes;
        acodes = cast(~isempty(b.categoryNames),'like',bcodes); % minimal value, or <undefined>
        c = b.cloneAsEmpty(); % preserve subclass
    elseif isnumeric(b) % && isa(a,'categorical')
        coder.internal.assert(isequal(b,-Inf),'MATLAB:categorical:InvalidComparisonTypes');
        acodes = a.codes;
        bcodes = cast(~isempty(a.categoryNames),'like',acodes); % minimal value, or <undefined>
        c = a.cloneAsEmpty(); % preserve subclass
    else
        [acodes,bcodes,tmp] = reconcileCategories(a,b,true); % require ordinal
        c = tmp.cloneAsEmpty();
    end
    
    % Missing elements have code zero, less than any legal code. They will not be
    % the max value unless there's nothing else, which is the correct behavior for
    % 'omitmissing'. For 'includemissing', set the code value for missing elements to the
    % largest integer to make sure they will be the max value when present.
    tmpCode = categorical.invalidCode(acodes); % acodes is always correct type by now
    if ~omitMissing
        acodes(acodes==categorical.undefCode) = tmpCode;
        bcodes(bcodes==categorical.undefCode) = tmpCode;
    end
    if nargout <= 1
        ccodes = maxFun(acodes,bcodes);
    else
        [ccodes,i] = maxFun(acodes,bcodes);
    end
end

if ~omitMissing
    ccodes(ccodes==tmpCode) = categorical.undefCode; % restore missing code
end

% No need to call castCodes on c, because nothing has been upcast. That's
% because there's either one input, or the two inputs have the exact same
% categories (they're both ordinal), and therefore same codes class.
c.codes = ccodes;
