function this = parenAssign(this,rhs,rowIndices,colIndices,varargin)
%
% THIS = PARENASSIGN(THIS,RHS,LINEARINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019-2022 The MathWorks, Inc.

% Only simple paren assignments come directly here; creation or multi-level
% paren assignments like d(i).Property = val go to subsasgn, then
% subsasgnParens, but ultimately end up here also.

nsubs = nargin - 2;
if nsubs == 0, error(message('MATLAB:atLeastOneIndexIsRequired')); end

if isnumeric(this) && isequal(this,[]) % creating, RHS must have been a datetime
    this = rhs;
    this.data = [];
end
deleting = false; % assume for now

thisData = this.data; this.data = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
szIn = size(thisData);

if isa(rhs,'datetime')
    if isa(this,'datetime') % assignment from a datetime array into another
        % Check that both datetimes either have or don't have timezones
        try
            checkCompatibleTZ(this.tz,rhs.tz);
        catch ME
            if ~matches(ME.identifier,"MATLAB:datetime:IncompatibleTZ") ...
                || (~isempty(rhs.tz) || any(isfinite(rhs)))
                rethrow(ME);
            else
                % Allow an unzoned NaT/Inf as the RHS even for assignment to zoned
            end
        end
        rhsData = rhs.data;
    else
        error(message('MATLAB:datetime:InvalidAssignmentLHS',class(rhs)));
    end
elseif matlab.internal.datatypes.isText(rhs) % assignment from date strings
    rhs = autoConvertStrings(rhs,this);
    if isa(rhs,'duration')
        error(message('MATLAB:datetime:InvalidAssignment'));
    end
    rhsData = rhs.data;
elseif isa(rhs, 'missing')
    rhsData = nan(size(rhs));
elseif isnumeric(rhs)
    % Check isnumeric/isequal before builtin to short-circuit for performance
    % and to distinguish between '' and [].
    deleting = isequal(rhs,[]) && builtin('_isEmptySqrBrktLiteral',rhs);
    if deleting % deletion by assignment
        switch nsubs
        case 1 % 1-D subscripting
            thisData(rowIndices) = [];
        case 2 % 2-D subscripting
            thisData(rowIndices,colIndices) = [];
        otherwise % >= 3, N-D subscripting
            thisData(rowIndices,colIndices,varargin{:}) = [];
        end
    else
        error(message('MATLAB:datetime:InvalidNumericAssignment',class(this)));
    end
else
    error(message('MATLAB:datetime:InvalidAssignment'));
end

if ~deleting
    switch nsubs
    case 1 % 1-D subscripting
        thisData(rowIndices) = rhsData;
    case 2 % 2-D subscripting
        thisData(rowIndices,colIndices) = rhsData;
    otherwise % >= 3, N-D subscripting
        thisData(rowIndices,colIndices,varargin{:}) = rhsData;
    end
    
    % Infill with NaN, not 0
    if ~isequal(size(thisData),szIn)
        nondefault = true(szIn); % pre-existing elements
        switch nsubs
        case 1 % 1-D subscripting
            nondefault(rowIndices) = true(size(rhsData)); % assigned elements
        case 2 % 2-D subscripting
            nondefault(rowIndices,colIndices) = true(size(rhsData)); % assigned elements
        otherwise % >= 3, N-D subscripting
            nondefault(rowIndices,colIndices,varargin{:}) = true(size(rhsData)); % assigned elements
        end
        thisData(~nondefault) = complex(NaN,0); % elements that were created by expansion, but not assigned
    end
end
this.data = thisData;
