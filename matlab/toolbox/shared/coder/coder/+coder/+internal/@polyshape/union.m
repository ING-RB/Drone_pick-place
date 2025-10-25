function varargout = union(subject, varargin)
%MATLAB Code Generation Library Function
% UNION Find the union of two polyshapes

%   Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(1, inf);
nargoutchk(0, 3);
coder.internal.polyshape.checkArray(subject);
[has_clip, collinear, simplify] = coder.internal.polyshape.parseIntersectUnionArgs(false, varargin{:});


if ~has_clip
    % when code generation allows arrays of objects vector
    % implementations of bool ops will be required.
    % branch should not be reached, added for safety
    coder.internal.error('Coder:common:TypeSpecMCOSArrayNotSupported', 'polyshape');
else
    nargoutchk(1,3);
    clip = varargin{1};
    coder.internal.polyshape.checkArray(clip);

    % Useful when array of object support is added to coder.
    if nargout > 1
        coder.internal.assert(isscalar(subject) && isscalar(clip), 'MATLAB:polyshape:noVertexMapping');
    end
    
    [PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, ...
        uint8(coder.internal.polyshapeHelper.booleanOpsEnum.UNION), simplify);

    varargout{1} = PG;
    
    if (nargout > 1)
        varargout{2} = shapeId;
        if (nargout > 2)
            varargout{3} = vertexId;
        end
    end
end
