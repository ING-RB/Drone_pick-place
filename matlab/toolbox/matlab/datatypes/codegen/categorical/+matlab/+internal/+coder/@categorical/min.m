function [c,i] = min(a,b,varargin) %#codegen
%MIN Smallest element in an ordinal categorical array.

%   Copyright 2020-2022 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

% Call processMinMaxOptionalInputs to update the missing flag arguments and
% create a wrapper function handle. See the function for more details.
[omitMissing,minFun] = processMinMaxOptionalInputs(@min,varargin{:});

% Unary min
if nargin < 2 ... % min(a)
        || (nargin > 2 && isnumeric(b) && isequal(b,[])) % min(a,[],...) but not min(a,[])
    if ~a.isOrdinal
        coder.internal.error('MATLAB:categorical:NotOrdinal');
    end
    
    acodes = a.codes;
    c = a.cloneAsEmpty();
    
    % Missing elements have code zero, less than any legal code. They will always
    % be the min value, which is the correct behavior for 'includemissing'. For
    % 'omitmissing', set the code value for missing elements to the largest
    % integer to make sure they will be not the min value unless there's nothing
    % else.
    tmpCode = categorical.invalidCode(acodes);
    if omitMissing
        acodes(acodes==categorical.undefCode) = tmpCode;
    end
    
    if nargin < 2
        if nargout <= 1
            ccodes = min(acodes);
        else
            [ccodes,i] = min(acodes);
        end
    else % nargin > 2
        if nargout <= 1
            ccodes = minFun(acodes,[]);
        else
            [ccodes,i] = minFun(acodes,[]);
        end
    end
    
% Binary min
else % min(a,b) or min(a,b,...)
    % Accept Inf as a valid "identity element" in the two-arg case. If compared
    % to <undefined> with 'omitmissing', the minimal value will be the result as
    % long as there is at least one category. If compared with 'includemissing',
    % <undefined> will be the result.
    if isnumeric(a) % && isa(b,'categorical')
        coder.internal.assert(isequal(a,Inf),'MATLAB:categorical:InvalidComparisonTypes');
        bcodes = b.codes;
        acodes = cast(length(b.categoryNames),'like',bcodes); % minimal value, or <undefined>
        c = b.cloneAsEmpty(); % preserve subclass
    elseif isnumeric(b) % && isa(a,'categorical')
        coder.internal.assert(isequal(b,Inf),'MATLAB:categorical:InvalidComparisonTypes');
        acodes = a.codes;
        bcodes = cast(length(a.categoryNames),'like',acodes); % minimal value, or <undefined>
        c = a.cloneAsEmpty(); % preserve subclass
    else
        [acodes,bcodes,tmp] = reconcileCategories(a,b,true); % require ordinal
        c = tmp.cloneAsEmpty();
    end
    
    % Missing elements have code zero, less than any legal code. They will always
    % be the min value, which is the correct behavior for 'includemissing'. For
    % 'omitmissing', set the code value for missing elements to the largest integer to
    % make sure they will be not the min value unless there's nothing else.
    tmpCode = categorical.invalidCode(acodes); % acodes is always correct type by now
    if omitMissing
        acodes(acodes==categorical.undefCode) = tmpCode;
        bcodes(bcodes==categorical.undefCode) = tmpCode;
    end
    if nargout <= 1
        ccodes = minFun(acodes,bcodes);
    else
        [ccodes,i] = minFun(acodes,bcodes);
    end
end

if omitMissing
    ccodes(ccodes==tmpCode) = categorical.undefCode; % restore missing code
end

% No need to call castCodes on c, because nothing has been upcast. That's
% because there's either one input, or the two inputs have the exact same
% categories (they're both ordinal), and therefore same codes class.
c.codes = ccodes;
