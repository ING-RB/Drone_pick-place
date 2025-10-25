function this = parenAssign(this,rhs,rowIndices,colIndices,varargin)
%
% THIS = PARENASSIGN(THIS,RHS,LINEARINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019 The MathWorks, Inc.

% Only simple paren assignments come directly here; creation goes to subsasgn,
% but ultimately ends up here also. categorical has no properties, and therefore
% no multi-level paren assignments.

import matlab.internal.datatypes.isScalarText

nsubs = nargin - 2;
if nsubs == 0, error(message('MATLAB:atLeastOneIndexIsRequired')); end

if isnumeric(this) && isequal(this,[]) % subscripted assignment to an array that doesn't exist
    this = rhs; % preserve the subclass
    this.codes = zeros(0,class(rhs.codes)); % account for the number of categories in b
end
deleting = false; % assume for now

anames = this.categoryNames;
numCatsOld = length(anames);

if isa(rhs,'categorical')
    bcodes = rhs.codes;
    bnames = rhs.categoryNames;
    % If b is categorical, its ordinalness has to match a, and if they are
    % ordinal, their categories have to match.
    if this.isOrdinal ~= rhs.isOrdinal
        error(message('MATLAB:categorical:OrdinalMismatchAssign'));
    elseif isequal(anames,bnames)
        % Identical category names => same codes class => no cast needed for acodes
    else
        if this.isOrdinal
            error(message('MATLAB:categorical:OrdinalCategoriesMismatch'));
        end
        % Convert b's codes to a's codes. a's new set of categories grows only by
        % the categories that are actually being assigned, and a never needs to
        % care about the others in b that are not assigned. 
        if isscalar(rhs)
            % When b is an <undefined> scalar, bcodes is already correct in 
            % a's codes (undefCode is the same in all categoricals) and no 
            % conversion is needed; otherwise, we can behave as if it only
            % has the one category, and conversion to a's codes is faster.
            if bcodes ~= 0 % categorical.undefCode
                [bcodes,anames] = convertCodesForSubsasgn(1,bnames{bcodes},anames,this.isProtected);
            end
        else
            [bcodes,anames] = convertCodesForSubsasgn(bcodes,bnames,anames,this.isProtected);
        end
    end
elseif isScalarText(rhs) || matlab.internal.datatypes.isCharStrings(rhs)
    [bcodes,bnames] = strings2codes(rhs);
    [bcodes,anames] = convertCodesForSubsasgn(bcodes,bnames,anames,this.isProtected);
elseif isa(rhs, 'missing')
    bcodes = zeros(size(rhs), 'uint8');
elseif isnumeric(rhs)
    % Check numeric before builtin to short-circuit for performance and to
    % distinguish between '' and [].
    deleting = isequal(rhs,[]) &&  builtin('_isEmptySqrBrktLiteral',rhs);
    if deleting % deletion by assignment
        % Deleting elements, but the categories stay untouched. No need
        % to possibly downcast a.codes with castCodes.
        switch nsubs
        case 1 % 1-D subscripting
            this.codes(rowIndices) = [];
        case 2 % 2-D subscripting
            this.codes(rowIndices,colIndices) = [];
        otherwise % >= 3, N-D subscripting
            this.codes(rowIndices,colIndices,varargin{:}) = [];
        end
    else
        error(message('MATLAB:categorical:InvalidRHS', class(this)));
    end
else
    error(message('MATLAB:categorical:InvalidRHS', class(this)));
end

if ~deleting
    % Upcast a's codes if necessary to account for any new categories
    if length(anames) > numCatsOld
        this.codes = categorical.castCodes(this.codes,length(anames));
    end
    switch nsubs
    case 1 % 1-D subscripting
        this.codes(rowIndices) = bcodes;
    case 2 % 2-D subscripting
        this.codes(rowIndices,colIndices) = bcodes;
    otherwise % >= 3, N-D subscripting
        this.codes(rowIndices,colIndices,varargin{:}) = bcodes;
    end
    this.categoryNames = anames;
end
