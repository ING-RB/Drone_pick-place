function this = parenAssign(this,rhs,rowIndices,colIndices,varargin)
%
% THIS = PARENASSIGN(THIS,RHS,LINEARINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019 The MathWorks, Inc.

% Only simple paren assignments come directly here; creation and multi-level
% paren assignments like d(i).Property = val go to subsasgn, then
% subsasgnParens, but ultimately end up here also.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

nsubs = nargin - 2;
if nsubs == 0, error(message('MATLAB:atLeastOneIndexIsRequired')); end

if isnumeric(this) && isequal(this,[]) % creating, RHS must have been a duration
    this = rhs;
    this.millis = [];
end
deleting = false; % assume for now

if isa(rhs,'duration')
    if isa(this,'duration') % assignment from a duration array into another
        rhsMillis = rhs.millis;
    else
        error(message('MATLAB:duration:InvalidAssignmentLHS',class(rhs)));
    end
elseif matlab.internal.datatypes.isText(rhs) % assignment from time strings
    try
        [~,rhsMillis,~] = duration.compareUtil(this,rhs);
    catch ME
        throwInstead(ME,{'MATLAB:duration:AutoConvertString','MATLAB:duration:InvalidComparison'},message('MATLAB:duration:InvalidAssignment'));
    end
elseif isa(rhs, 'missing')
    rhsMillis = double(rhs);
elseif isnumeric(rhs) || islogical(rhs)
    % Check isnumeric/isequal before builtin to short-circuit for performance
    % and to distinguish between '' and [].
    deleting = isequal(rhs,[]) && builtin('_isEmptySqrBrktLiteral',rhs); % deletion by assignment
    if deleting
        switch nsubs
        case 1 % 1-D subscripting
            this.millis(rowIndices) = [];
        case 2 % 2-D subscripting
            this.millis(rowIndices,colIndices) = [];
        otherwise % >= 3, N-D subscripting
            this.millis(rowIndices,colIndices,varargin{:}) = [];
        end
    else
        try
            rhsMillis = datenumToMillis(rhs,true); % allow non-double numeric
        catch ME
            throwInstead(ME,{'MATLAB:datetime:DurationConversion'},message('MATLAB:duration:InvalidAssignment'));
        end
    end
else
    error(message('MATLAB:duration:InvalidAssignment'));
end

if ~deleting
    switch nsubs
    case 1 % 1-D subscripting
        this.millis(rowIndices) = rhsMillis;
    case 2 % 2-D subscripting
        this.millis(rowIndices,colIndices) = rhsMillis;
    otherwise % >= 3, N-D subscripting
        this.millis(rowIndices,colIndices,varargin{:}) = rhsMillis;
    end
end
