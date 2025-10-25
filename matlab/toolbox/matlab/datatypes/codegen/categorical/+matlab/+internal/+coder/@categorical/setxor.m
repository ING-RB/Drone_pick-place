function [c,ia,ib] = setxor(ain,bin,varargin) %#codegen
%SETXOR Set exclusive-or for categorical arrays.

%   Copyright 2020 The MathWorks, Inc.

narginchk(2,Inf);

% catch the case where a varargin input is categorical and is dispatched here.
coder.internal.assert(isa(ain,'categorical') || isa(bin,'categorical'),'MATLAB:categorical:setmembership:UnknownInput');

if isa(ain,'categorical') && isa(bin,'categorical')
    coder.internal.errorIf(ain.isOrdinal ~= bin.isOrdinal, ...
                           'MATLAB:categorical:setmembership:OrdinalMismatch','SETXOR');
    a = ain;
    b = bin;
elseif isa(ain,'categorical')
    coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(bin) || ...
                          matlab.internal.coder.datatypes.isCharStrings(bin), ...
                          'MATLAB:categorical:setmembership:TypeMismatch','SETXOR');
    a = ain;
    b = strings2categorical(bin,ain);
else % bin is a categorical
    coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(ain) || ...
                          matlab.internal.coder.datatypes.isCharStrings(ain), ...
                          'MATLAB:categorical:setmembership:TypeMismatch','SETXOR');
    a = strings2categorical(ain,bin);
    b = bin;
end

isOrdinal = a.isOrdinal;
a = a(:); b = b(:);

acodes = a.codes;
anames = a.categoryNames;
if coder.internal.isConst(size(anames))
    % Ensure anames is homogeneous
    coder.varsize('anames',[],[0 0]);
end
    
bnames = b.categoryNames;
if coder.internal.isConst(size(bnames))
    % Ensure bnames is homogeneous
    coder.varsize('bnames',[],[0 0]);
end

haveSameCategories = isequal(bnames,anames);
if coder.internal.isConst(haveSameCategories) && haveSameCategories
    % If the categories are known at compile time and they are the same, then
    % avoid extra work and simply use anames as output category names and
    % directly copy b.codes.
    bcodes = b.codes;
    cnames = anames;
else
    coder.internal.errorIf(~haveSameCategories && isOrdinal,'MATLAB:categorical:OrdinalCategoriesMismatch');
    % Convert b to a's categories, possibly expanding the set of categories
    % if neither array is protected.
    [codes,cnames] = categorical.convertCodes(b.codes,bnames,anames,a.isProtected,b.isProtected);
    % In certain cases, when b.codes is varsized vector, calling convertCodes
    % followed by set functions leads to codes becoming variable sized in all
    % dims. To avoid that explicitly create a skeleton of the same size as
    % b.codes and fill it in a loop to ensure it retains the correct size.
    bcodes = zeros(size(b.codes),'like',codes);
    for i = 1:numel(bcodes)
        bcodes(i) = codes(i);
    end
end

% Make sure acodes and bcodes have the same integer class, but if either
% contains <undefined>, cast to float to leverage builtin's NaN handling
[acodes, bcodes] = categorical.castCodesForBuiltins(acodes,bcodes);

[ccodes,ia,ib] = categorical.setmembershipHelper(@setxor,acodes,bcodes,varargin{:});

c = categorical(matlab.internal.coder.datatypes.uninitialized);
c.isProtected = a.isProtected;
c.isOrdinal = a.isOrdinal;
c.categoryNames = cnames;

if isfloat(ccodes)
    % Cast back to integer codes, including NaN -> <undefined>
    c.codes = categorical.castCodes(ccodes,length(cnames));
else
    c.codes = ccodes;
end