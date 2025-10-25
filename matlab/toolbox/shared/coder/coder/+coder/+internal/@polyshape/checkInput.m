function [X, Y, type_con, simplify, collinear] = checkInput(varargin)
%MATLAB Code Generation Library Function
% Parse input and extract vertices of polyshape, values of simplify,
% collinear and boundary type.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.prefer_const(varargin);

coder.internal.assert(iscell(varargin{1}) || isnumeric(varargin{1}), ...
    'MATLAB:polyshape:xyNumericCell');

% parse and check coordinates
if iscell(varargin{1})
    [X, Y] = coder.internal.polyshape.getXYcell(varargin{:});
    xy2input = true;
else
    [X, Y, xy2input] = coder.internal.polyshape.getXY(varargin{:});
end

coder.internal.assert(isreal(X) && isreal(Y), 'MATLAB:polyshape:xyValueError');

tf = false;
for k = 1:numel(X)
    tf = tf || ( isnan(X(k)) ~= isnan(Y(k)) );
    if(tf) 
        break; 
    end
end
coder.internal.errorIf(tf && ~xy2input, 'MATLAB:polyshape:oneInputNanInconsistent');
coder.internal.errorIf(tf && xy2input, 'MATLAB:polyshape:twoInputNanInconsistent');

if ~isa(X, 'double')
    X = double(X);
end

if ~isa(Y, 'double')
    Y = double(Y);
end

simplify = 'd';
collinear = 'd';
type_con = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto);
% parse and check Name Values
for ia = 2:numel(varargin)

    if(ia == 2 && xy2input)
        continue;
    end

    if(xy2input && ~mod(ia,2))
        continue;
    end

    if(~xy2input && mod(ia,2))
        continue;
    end

    this_arg = varargin{ia};
    coder.internal.errorIf(nargin < ia + 1, 'MATLAB:polyshape:nameValuePairError');
    next_arg = varargin{ia+1};
    coder.internal.assert(coder.internal.isCharOrScalarString(this_arg), ...
        'MATLAB:polyshape:constructorParameter');

    % Optional args must be const for codegen
    coder.internal.assert(coder.internal.isConst(this_arg), ...
        'Coder:toolbox:OptionInputsMustBeConstant', 'polyshape');

    lengthArg = length(this_arg);

    issimplify = strncmpi(this_arg, 'Simplify', max(2, lengthArg));
    iskeepCollinear = strncmpi(this_arg, 'KeepCollinearPoints', max(1, lengthArg));
    isbndOrient = strncmpi(this_arg, 'SolidBoundaryOrientation', max(2, lengthArg));

    coder.internal.assert(issimplify || iskeepCollinear || isbndOrient, ...
        'MATLAB:polyshape:constructorParameter');
    
    if issimplify
        
        coder.internal.assert(isscalar(next_arg) && (islogical(next_arg) || ...
            isnumeric(next_arg)), 'MATLAB:polyshape:simplifyValue');

        coder.internal.assert(double(next_arg)==1 || double(next_arg)==0, ...
            'MATLAB:polyshape:simplifyValue');
        if double(next_arg) == 1
            simplify = 't';
        else
            simplify = 'f';
        end
        
    elseif iskeepCollinear

        collinear = coder.internal.polyshape.checkCollinear(next_arg);

    elseif isbndOrient
        
        coder.internal.assert(coder.internal.isCharOrScalarString(next_arg), ...
            'MATLAB:polyshape:orientationValue')
        type_con = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.Invalid);
        nextss = string(next_arg);
        n = strlength(nextss);
        if strncmpi(nextss, 'auto', max(1, n)) 
            type_con = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto);
        elseif strncmpi(nextss, 'ccw', max(2, n)) 
            type_con = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCCW);
        elseif strncmpi(nextss, 'cw', max(2, n))
            type_con = uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW);
        end

        coder.internal.errorIf(type_con == uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.Invalid), ...
            'MATLAB:polyshape:orientationValue');

    end

end
