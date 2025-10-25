function c = times(a,b)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isCharStrings
import matlab.internal.datatypes.isScalarText

% Accept 1 as a valid "identity element".
if isnumeric(a) && isequal(a,1)
    c = b;
    return;
elseif isnumeric(b) && isequal(b,1)
    c = a;
    return;
elseif ~isa(a,'categorical') || ~isa(b,'categorical')
    if isScalarText(a) || isCharStrings(a) % && isa(b,'categorical'); only allow scalar string
        [acodes, anames] = strings2codes(a);
        if ischar(anames), anames={anames}; end
        bnames = b.categoryNames;
        bcodes = b.codes;
        c = b;
        c.isOrdinal = b.isOrdinal;
        c.isProtected = b.isProtected;
    elseif isScalarText(b) || isCharStrings(b) % && isa(a,'categorical')
        [bcodes, bnames] = strings2codes(b);
        if ischar(bnames), bnames={bnames}; end
        anames = a.categoryNames;
        acodes = a.codes;
        c = a;
        c.isOrdinal = a.isOrdinal;
        c.isProtected = a.isProtected;
    elseif isstring(a) || isstring(b) % non-scalar string is an error, but cellstr is grandfathered in
        error(message('MATLAB:categorical:times:TypeMismatchString'));
    else
        error(message('MATLAB:categorical:times:TypeMismatch'));
    end
else
    anames = a.categoryNames; acodes = a.codes;
    bnames = b.categoryNames; bcodes = b.codes;
    c = a;
    c.isOrdinal = (a.isOrdinal && b.isOrdinal);
    c.isProtected = (a.isProtected || b.isProtected);
end

na = length(anames);
nb = length(bnames);
anames = repmat(anames(:)',nb,1); anames = anames(:);
bnames = repmat(bnames(:)',1,na); bnames = bnames(:);
c.categoryNames = append(anames,' ',bnames);
numCats = na*nb;
acodes = categorical.castCodes(acodes, numCats);
bcodes = categorical.castCodes(bcodes, numCats);
c.codes = bcodes + nb*(acodes-1);
c.codes( acodes==c.undefCode | bcodes==c.undefCode ) = c.undefCode; % undefined in either -> undefined in result

