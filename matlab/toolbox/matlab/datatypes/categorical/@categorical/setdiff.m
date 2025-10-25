function [c,i] = setdiff(a,b,varargin)
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
    if isScalarText(a) || isCharStrings(a) % only allow scalar string
        a = strings2categorical(a,b);
    elseif isScalarText(b) || isCharStrings(b)
        b = strings2categorical(b,a);
    elseif isstring(a) || isstring(b) % non-scalar string is an error, but cellstr is grandfathered in
        error(message('MATLAB:categorical:setmembership:TypeMismatchString','SETDIFF'));
    else
        error(message('MATLAB:categorical:setmembership:TypeMismatch','SETDIFF'));
    end
elseif a.isOrdinal ~= b.isOrdinal
    error(message('MATLAB:categorical:setmembership:OrdinalMismatch','SETDIFF'));
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
        [ccodes,i] = setdiff(acodes,bcodes,varargin{:});
    else
        ccodes = setdiff(acodes,bcodes,varargin{:});
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
