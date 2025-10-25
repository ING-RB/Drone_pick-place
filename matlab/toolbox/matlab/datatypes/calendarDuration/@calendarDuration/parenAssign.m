function this = parenAssign(this,rhs,rowIndices,colIndices,varargin)
%
% THIS = PARENASSIGN(THIS,RHS,LINEARINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES)
% THIS = PARENASSIGN(THIS,RHS,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019-2021 The MathWorks, Inc.

% Only simple paren assignments come directly here; creation and multi-level
% paren assignments like d(i).Property = val go to subsasgn, then
% subsasgnParens, but ultimately end up here also.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

nsubs = nargin - 2;
if nsubs == 0, error(message('MATLAB:atLeastOneIndexIsRequired')); end

if isnumeric(this) && isequal(this,[]) % creating, RHS must have been a duration
    this = rhs;
    this.components.months = [];
    this.components.days = [];
    this.components.millis = [];
end
deleting = false; % assume for now

theComponents = this.components; this.components = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing

if isa(rhs,'calendarDuration')
    if isa(this,'calendarDuration') % assignment from a calendarDuration array into another
        rhsComponents = rhs.components;
    else
        error(message('MATLAB:calendarDuration:InvalidAssignmentLHS',class(rhs)));
    end
elseif isa(rhs, 'missing')
    rhsComponents = struct('months',0,'days',0,'millis',double(rhs));
elseif isnumeric(rhs) && isequal(rhs,[]) && builtin('_isEmptySqrBrktLiteral',rhs) % deleting
    % Check isnumeric/isequal before builtin to short-circuit for performance
    % and to distinguish between '' and [].
    deleting = true;
    fnames = fieldnames(theComponents);
    for i = 1:3
        fname = fnames{i};
        if isequal(theComponents.(fname),0)
            % leave the scalar zero placeholder
        else
            % This cannot be done 'in-place': 'shortening' (i.e. deleting elements from) the array 
            % "theComponents.(fname)" triggers new memory allocation (to hold the 'shorter' array).
            switch nsubs
            case 1 % 1-D subscripting
                theComponents.(fname)(rowIndices) = [];
            case 2 % 2-D subscripting
                theComponents.(fname)(rowIndices,colIndices) = [];
            otherwise % >= 3, N-D subscripting
                theComponents.(fname)(rowIndices,colIndices,varargin{:}) = [];
            end
        end
    end
elseif isa(rhs,'duration')
    rhsComponents = struct('months',0,'days',0,'millis',milliseconds(rhs));
else
    try
        % double and logical input treated as a multiple of 24 hours.
        rhsComponents = struct('months',0,'days',0,'millis',datenumToMillis(rhs));
    catch ME
        throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:calendarDuration:InvalidAssignment'));
    end
end

if ~deleting
    sz = calendarDuration.getFieldSize(theComponents);
    fnames = fieldnames(theComponents);
    for i = 1:3
        fname = fnames{i};
        rf = rhsComponents.(fname);
        f = theComponents.(fname); theComponents.(fname) = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
        if isequal(rf,0) && isequal(f,0)
            % leave the scalar zero placeholder
        else
            if isequal(f,0)
                f = repmat(f,sz);
            end
            switch nsubs
            case 1 % 1-D subscripting
                f(rowIndices) = rf; % might be scalar expansion of rf
            case 2 % 2-D subscripting
                f(rowIndices,colIndices) = rf; % might be scalar expansion of rf
            otherwise % >= 3, N-D subscripting
                f(rowIndices,colIndices,varargin{:}) = rf; % might be scalar expansion of rf
            end
        end
        theComponents.(fname) = f; % Make sure to replace the emptied-out field in all cases
    end
end
this.components = theComponents;
