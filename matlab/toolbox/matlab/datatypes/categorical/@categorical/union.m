function [c,ia,ib] = union(a,b,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isCharStrings

narginchk(2,Inf);
if ~iscategorical(a) && ~iscategorical(b) 
    % catch the case where a varargin input is categorical and is dispatched here.
    error(message('MATLAB:categorical:setmembership:UnknownInput'));
end

if ~isa(a,'categorical') || ~isa(b,'categorical')
    % Accept [] as a valid "identity element" for either arg.
    if isScalarText(a) || isCharStrings(a) % only allow scalar string
        a = strings2categorical(a,b);
    elseif isnumeric(a) && isequal(a,[])
        a = b; a.codes = cast([],'like',b.codes);
    elseif isScalarText(b) || isCharStrings(b) % only allow scalar string
        b = strings2categorical(b,a);
    elseif isnumeric(b) && isequal(b,[])
        b = a; b.codes = cast([],'like',a.codes);
    elseif isstring(a) || isstring(b) % non-scalar string is an error, but cellstr is grandfathered in
        error(message('MATLAB:categorical:setmembership:TypeMismatchString','UNION'));
    else
        error(message('MATLAB:categorical:setmembership:TypeMismatch','UNION'));
    end
elseif a.isOrdinal ~= b.isOrdinal
    error(message('MATLAB:categorical:setmembership:OrdinalMismatch','UNION'));
end
isOrdinal = a.isOrdinal;
a = a(:); b = b(:);

acodes = a.codes;
cnames = a.categoryNames;
if isequal(b.categoryNames,cnames)
    bcodes = b.codes;
elseif ~isOrdinal
    % Convert b to a's categories, possibly expanding the set of categories
    % if neither array is protected.
    [bcodes,cnames] = convertCodes(b.codes,b.categoryNames,cnames,a.isProtected,b.isProtected);
else
    error(message('MATLAB:categorical:OrdinalCategoriesMismatch'));
end

% Make sure acodes and bcodes have the same integer class, but if either
% contains <undefined>, cast to float to leverage builtin's NaN handling
[acodes, bcodes] = categorical.castCodesForBuiltins(acodes,bcodes);

try
    if nargout > 1
        [ccodes,ia,ib] = union(acodes,bcodes,varargin{:});
    else
        ccodes = union(acodes,bcodes,varargin{:});
    end
catch ME
    throw(ME);
end

if isfloat(ccodes)
    % Cast back to integer codes, including NaN -> <undefined>
    ccodes = categorical.castCodes(ccodes,length(cnames));
end
c = a; % preserve subclass
c.codes = ccodes;
c.categoryNames = cnames;
