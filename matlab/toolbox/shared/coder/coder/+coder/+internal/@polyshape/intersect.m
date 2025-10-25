function varargout = intersect(subject, varargin)
%MATLAB Code Generation Library Function
% INTERSECT Find the intersection of two polyshapes or a polyshape and a
% line

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

narginchk(1, inf);
ns = coder.internal.polyshape.checkArray(subject); %#ok<NASGU> 
[has_clip, collinear, simplify] = coder.internal.polyshape.parseIntersectUnionArgs(true, varargin{:});

if ~has_clip
    nargoutchk(1, 3);
    if isscalar(subject)
        % special treatment here. booleanVec returns an empty shape if
        % subject is a scalar shape
        [PG, shapeId, vertexId] = booleanFun(subject, subject, collinear, ...
            uint8(coder.internal.polyshapeHelper.booleanOpsEnum.INTERSECT), ...
            simplify);
        
        % shapeId(shapeId==2) = 1;
    else
        % when code generation allows arrays of objects vector
        % implementations of bool ops will be required.
        % branch should not be reached, added for safety
        coder.internal.error('Coder:common:TypeSpecMCOSArrayNotSupported', 'polyshape');
    end
    varargout{1} = PG;
    if nargout >= 2
        varargout{2} = shapeId;
        if nargout == 3
            varargout{3} = vertexId;
        end
    end
else
    clip = varargin{1};
    pip = isa(clip, 'coder.internal.polyshape');
    if (pip)
        nargoutchk(1, 3);
        
        nc = coder.internal.polyshape.checkArray(clip); %#ok<NASGU> 

        % Useful when array of object support is added to coder.
        if nargout > 1
            coder.internal.assert(isscalar(subject) && isscalar(clip), 'MATLAB:polyshape:noVertexMapping');
        end
        
        [PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, ...
            uint8(coder.internal.polyshapeHelper.booleanOpsEnum.INTERSECT), ...
            simplify);

        varargout{1} = PG;
        if nargout >= 2
            varargout{2} = shapeId;
        end
        if nargout == 3
            varargout{3} = vertexId;
        end
    else
        % isnumeric(clip) must be true
        
        coder.internal.assert(isscalar(subject), 'MATLAB:polyshape:scalarPolyshapeError');
        nargoutchk(1, 2);
        
        param = struct;
        param.allow_inf = false;
        param.allow_nan = false; % allow 1 polyline as input
        param.one_point_only = false;
        param.errorOneInput = 'MATLAB:polyshape:lineInputError';
        param.errorTwoInput = 'MATLAB:polyshape:lineInputError';
        param.errorValue = 'MATLAB:polyshape:linePointValue';
        [X, Y] = coder.internal.polyshape.checkPointArray(param, clip);
       
        coder.internal.errorIf(numel(X) < 2, 'MATLAB:polyshape:lineMin2Points');

        if collinear ~= 'd'
            coder.internal.warning('MATLAB:polyshape:collinearNoEffect');
        end

        if subject.isEmptyShape()
            out1 = zeros(0, 2);
            out2 = [X Y];
        else
            [out1, out2] = lineintersect(subject, [X Y]);
        end
        
        varargout{1} = out1;
        if nargout == 2
            varargout{2} = out2;
        end
    end
end

% LocalWords:  polyshapes Vec polyline
