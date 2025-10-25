classdef polyshape
    %MATLAB Code Generation Library Function

    %   Copyright 2022-2024 The MathWorks, Inc.

    %#codegen

    properties (Dependent)
        Vertices
    end

    properties (Dependent = true, SetAccess = private)
        NumHoles
        NumRegions
    end

    properties (Access = private)
        % To indicate polyshape's simplification state
        % -1: unknown   0: not simplified   1: simplified
        SimplifyState;

        % State to record whether to keep collinear pts
        % false is default, not useful when simplify is
        % set to false.
        KeepCollinearPoints;

        % polyImpl - Underlying builtin polygon object
        % an instance of coder.internal.polyshapeHelper.polygon
        polyImpl;
    end

    methods
        %dependent property
        function nh = get.NumHoles(pshape)
            nh = getNumHoles(pshape.polyImpl);
        end

        %dependent property
        function nr = get.NumRegions(pshape)
            nh = getNumHoles(pshape.polyImpl);
            nr = pshape.polyImpl.numBoundaries-nh;
        end

        %get/set Vertices[]
        function V = get.Vertices(pshape)
            V = getPoints(pshape.polyImpl);
        end

        function PG = set.Vertices(PG, ~)
            % Erroring out. Can be implemented if all properties remain var
            % sized. Need to implement functions to modify boundary in
            % polygon.m and boundary2D.m
            coder.internal.errorIf(true, 'Coder:toolbox:PolyVertDotAssgnFail');
        end

        %constructor
        function PG = polyshape(varargin)
            
            coder.internal.assert(coder.areUnboundedVariableSizedArraysSupported, ...
                'Coder:toolbox:FuncNeedsDynamic', 'polyshape');

            PG.SimplifyState = -1;
            PG.KeepCollinearPoints = false;

            if nargin == 0
                PG.polyImpl = coder.internal.polyshapeHelper.polygon();
                PG.SimplifyState = 1;
            else
                [X, Y, tc, s, collinear] = coder.internal.polyshape.checkInput(varargin{:});
                PG.polyImpl = coder.internal.polyshapeHelper.polygon(X, Y, tc, uint32(0));
                if collinear == 't'
                    PG.KeepCollinearPoints = true;
                end
                if s ~= 'f'
                    PG = checkAndSimplify(PG, true);
                end
            end
        end

        function tf = issimplified(PG)
            % Returns simplified status of polyshape
            % Add array check when arrays of objects is supported
            if PG.isEmptyShape()
                tf = true;
            elseif PG.SimplifyState >= 0
                tf = logical(PG.SimplifyState);
            else
                [~, canBeSimplified] = checkAndSimplify(PG, false);
                tf = ~canBeSimplified;
            end
        end

        %overloaded function
        function TF = isequal(varargin)
            %ISEQUAL Determine if polyshapes are equal
            %
            % TF = ISEQUAL(pshape1, pshape2) returns 1 (true) if the two input polyshape objects
            % are the equal.
            %
            % TF = ISEQUAL(pshape1, pshape2, ..., pshapeN) returns true if pshape1, pshape2, ...,
            % pshapeN are equal.

            narginchk(2, inf);
            for jj = 1 : nargin
                if ~isa(varargin{jj}, 'coder.internal.polyshape')
                    TF = false;
                    return;
                end
            end

            PG = varargin{1};
            for jj = 2 : nargin
                other = varargin{jj};
                if numel(PG) ~= numel(other) || ~all(size(PG) == size(other))
                    TF = false;
                    return;
                end
                for i = 1 : numel(PG)
                    if PG(i).SimplifyState ~= other(i).SimplifyState || ...
                            PG(i).KeepCollinearPoints ~= other(i).KeepCollinearPoints
                        TF = false;
                        return;
                    else
                        eq = isEqual(PG(i).polyImpl, other(i).polyImpl);
                        if ~eq
                            TF = false;
                            return;
                        end
                    end
                end
            end
            TF = true;
        end

    end

    methods(Access = private)

        function [PG2, canBeSimplified] = checkAndSimplify(PG0, warn_can_simpl)
            if ~PG0.isEmptyShape()
                PG2 = extractPropsAndCallSimplifyAPI(PG0, PG0.KeepCollinearPoints);
            else
                PG2 = coder.internal.polyshape();
            end
            PG2.SimplifyState = 1;
            PG2.KeepCollinearPoints = PG0.KeepCollinearPoints;

            if PG2.isEqualShape(PG0)
                canBeSimplified = false;
                % copy the accessOrder since the shape is the same
                PG2.polyImpl.accessOrder = PG0.polyImpl.accessOrder;
            else
                canBeSimplified = true;
            end
            if canBeSimplified && warn_can_simpl
                coder.internal.warning('MATLAB:polyshape:repairedBySimplify');
            end
        end

        %convenience method to check if a shape is empty
        function TF = isEmptyShape(PG)
            TF = (PG.numboundaries == 0);
        end

        %rough comparison of two shapes
        function TF = isEqualShape(PG, other)
            atol = max(1.0e-10, 1e-10*abs(PG.area));
            ptol = max(1.0e-9, 1e-9*abs(PG.perimeter));
            if numsides(PG) ~= numsides(other) || ...
                    PG.NumRegions ~= other.NumRegions || ...
                    PG.NumHoles ~= other.NumHoles || ...
                    abs(area(PG) - area(other)) > atol || ...
                    abs(perimeter(PG) - perimeter(other)) > ptol
                TF = false;
            else
                TF = true;
            end
        end
    end

    methods (Hidden = true)
        %overloaded, the same as isequal
        function TF = isequaln(varargin)
            TF = isequal(varargin{:});
        end

        %convenient function for utility functions to set SimplifyState
        function PG = setSimplified(PG, value)
            if islogical(value) && isscalar(value)
                PG.SimplifyState = value;
            end
        end

        %convenient function for testing
        function TF = isKeepCollinear(PG)
            TF = PG.KeepCollinearPoints;
        end
    end

    methods (Access = private, Hidden = true)
        
        % Helper functions to extract polyshape properties and call clipper API

        % Calls clipper for simplify
        polyshapeObj = extractPropsAndCallSimplifyAPI(pshape, collinear);
        % Calls clipper for polybuffer
        polyshapeObj = extractPropsAndCallBufferAPI(pshape, d, jointType, miterLimit);
        % Calls clipper for rmslivers
        polygonObj = cleanup(pshape, d);
        % Calls clipper for intersect (intersection of polyshape and line)
        [ptsInside, ptsOutside] = lineintersect(pshape, lineseg);

        % Helper function to allow deep copy of handles. Creates new handle
        % and assigns to polyImpl.
        function pshape = copy(obj)
            pshape = obj;
            pshape.polyImpl = copy(obj.polyImpl);
        end
        
        % Helper functions to call clipper for boolean methods

        % Parse args passed to boolean method
        polyshapeObj = booleanFun(subject, clip, collinear, boolFunEnum, simplify);
        % Extract polyshape properties and call clipper for boolean method
        polygonObj = booleanFunDispatch(subject, clip, collinear, boolFunEnum, simplify);
    end

    methods (Static, Access = public, Hidden = true)
        function MLObj = matlabCodegenFromRedirected(coderObj)
            MLObj = polyshape();
            % Boundaries have to be added one at a time to preserve
            % orientation.
            for i = 1:coderObj.numboundaries
                [bx, by] = coderObj.boundary(i);
                bType = coder.internal.polyshape.getBoundaryTypeChar( ...
                    coderObj.polyImpl.boundaries.bType(i));
                MLObj = MLObj.addboundary(bx, by, 'Simplify', false, ...
                    ... % KeepCollinearPoints shouldn't have any effect
                    ... % preserving it in the final object by passing it as N-V pair.
                    'KeepCollinearPoints', coderObj.KeepCollinearPoints, ... 
                    'SolidBoundaryOrientation', bType);
            end
            if coderObj.SimplifyState == 1
                % simplify function call isn't strictly necessary, 
                % but, better to be safe than sorry.
                MLObj = MLObj.simplify();
            elseif coderObj.SimplifyState == 0 
                % Set state to false
                MLObj = MLObj.setSimplified(false);
            end % Leave it in unspecified (-1) state
        end

        function coderObj = matlabCodegenToRedirected(MLObj)

            import coder.internal.polyshape.reshapeAndCastToCoderClass;

            MLObjStruct = saveobj(MLObj);
            vtx = MLObjStruct.Vertices;
            binfo = MLObjStruct.BoundaryInfo;
            pinfo = MLObjStruct.PolygonInfo;
            [nd, nb] = size(binfo);
            assert(nd==12) %<HINT>
            if nb == 0
                coderObj = coder.internal.polyshape();
                return
            end

            bdObj = coder.internal.polyshapeHelper.boundary2D();
            bdObj.bType = reshapeAndCastToCoderClass(binfo(1,:), bdObj.bType);
            bdObj.clean = reshapeAndCastToCoderClass(binfo(3,:), bdObj.clean);
            bdObj.area = reshapeAndCastToCoderClass(binfo(4,:), bdObj.area);
            bdObj.perimeter = reshapeAndCastToCoderClass(binfo(5,:), bdObj.perimeter);
            bdObj.centroid.X = reshapeAndCastToCoderClass(binfo(6,:), bdObj.centroid.X);
            bdObj.centroid.Y = reshapeAndCastToCoderClass(binfo(7,:), bdObj.centroid.Y);
            bdObj.bbox.loX = reshapeAndCastToCoderClass(binfo(8,:), bdObj.bbox.loX);
            bdObj.bbox.loY = reshapeAndCastToCoderClass(binfo(9,:), bdObj.bbox.loY);
            bdObj.bbox.hiX = reshapeAndCastToCoderClass(binfo(10,:), bdObj.bbox.hiX);
            bdObj.bbox.hiY = reshapeAndCastToCoderClass(binfo(11,:), bdObj.bbox.hiY);
            
            % In Coder, the derived properties are calculated during
            % construction. Get the properties that haven't been calculated
            % by the MATLAB polyshape object.
            bdsToUpdate = find(~bdObj.clean);
            % Using the MATLAB polyshape object to update properties will be faster, 
            % since this method is invoked in MATLAB context.
            for ii = bdsToUpdate
                % scalar assignment, doesn't require reshape call.
                bdObj.area(ii) = cast(MLObj.area(ii),'like',bdObj.area);
                bdObj.perimeter(ii) = cast(MLObj.perimeter(ii),'like',bdObj.perimeter);
                [cx,cy] = MLObj.centroid(ii);
                bdObj.centroid.X(ii) = cast(cx,'like',bdObj.centroid.X);
                bdObj.centroid.Y(ii) = cast(cy,'like',bdObj.centroid.Y);
                [bx,by] = MLObj.boundingbox;
                bdObj.bbox.loX(ii) = cast(bx(1),'like',bdObj.bbox.loX);
                bdObj.bbox.loY(ii) = cast(by(1),'like',bdObj.bbox.loY);
                bdObj.bbox.hiX(ii) = cast(bx(2),'like',bdObj.bbox.hiX);
                bdObj.bbox.hiY(ii) = cast(by(2),'like',bdObj.bbox.hiY);
                bdObj.clean(ii) = cast(1,'like',bdObj.clean);
            end

            x = reshape(vtx(:,1), 1, []);
            y = reshape(vtx(:,2), 1, []);
            x = [x nan]; % use nan to close last boundary
            y = [y nan];
            enPtr = find(isnan(x));
            stPtr = [1 enPtr(1:end-1)+1];
            x(enPtr) = x(stPtr);
            y(enPtr) = y(stPtr);
            assert(numel(enPtr) == nb);
            assert(numel(stPtr) == nb);

            bdObj.stPtr = reshapeAndCastToCoderClass(stPtr, bdObj.stPtr);
            bdObj.enPtr = reshapeAndCastToCoderClass(enPtr, bdObj.enPtr);

            ptObj = coder.internal.polyshapeHelper.point;
            ptObj.X = x;
            ptObj.Y = y;
            bdObj.vertices = ptObj;
            
            pg = coder.internal.polyshapeHelper.polygon;
            pg.numBoundaries = nb;
            polyMask = cast(pinfo(1),'uint64');
            pg.polyArea = pinfo(2);
            pg.polyPerimeter = pinfo(3);
            pg.polyCentroid.X = pinfo(4);
            pg.polyCentroid.Y = pinfo(5);
            pg.polyBbox.loX = pinfo(6);
            pg.polyBbox.loY = pinfo(7);
            pg.polyBbox.hiX = pinfo(8);
            pg.polyBbox.hiY = pinfo(9);
            
            pg.polyNumPoints = reshapeAndCastToCoderClass( ...
                bitand(uint64(0xFFFFFFFF), polyMask), pg.polyNumPoints);
            % In coder, polyNumPoints count the last point of the boundary.
            % which is same as the first point, since all boundaries are
            % closed in a polyshape object.
            pg.polyNumPoints = pg.polyNumPoints + cast(nb,'like',pg.polyNumPoints);
            pg.nestingResolved = reshapeAndCastToCoderClass( ...
                bitand(uint64(0xFF00000000), polyMask), pg.nestingResolved);
            pg.polyClean = reshapeAndCastToCoderClass( ...
                bitand(uint64(0xFF0000000000), polyMask), pg.polyClean);
            pg.fillingRule = reshapeAndCastToCoderClass( ...
                bitand(uint64(0xFF000000000000), polyMask), pg.polyClean);
            
            if ~pg.polyClean
                pg.polyArea = cast(MLObj.area,'like',pg.polyArea);
                pg.polyPerimeter = cast(MLObj.perimeter,'like',pg.polyPerimeter);
                [cx,cy] = MLObj.centroid;
                pg.polyCentroid.X = cast(cx,'like',pg.polyCentroid.X);
                pg.polyCentroid.Y = cast(cy,'like',pg.polyCentroid.Y);
                [bx,by] = MLObj.boundingbox;
                pg.polyBbox.loX = cast(bx(1),'like',pg.polyBbox.loX);
                pg.polyBbox.loY = cast(by(1),'like',pg.polyBbox.loY);
                pg.polyBbox.hiX = cast(bx(2),'like',pg.polyBbox.hiX);
                pg.polyBbox.hiY = cast(by(2),'like',pg.polyBbox.hiY);
                pg.polyClean = cast(1,'like',pg.polyClean);
            end

            pg.boundaries = bdObj;
            % The ML object is not considered as 'sorted' by coder.
            % However, the order of boundaries is preserved.
            pg.accessOrder = pg.accessOrder.updateAccessOnAdd(nb);
            
            coderObj = coder.internal.polyshape();
            coderObj.polyImpl = pg;
            coderObj.SimplifyState = MLObjStruct.SimplifyState;
            coderObj.KeepCollinearPoints  = MLObjStruct.KeepCollinearPoints;
        end

        function coderProp = reshapeAndCastToCoderClass(MLProp, coderProp)
            coderProp = cast(reshape(MLProp, 1, []), 'like', coderProp);
        end

        function bType = getBoundaryTypeChar(bTypeEnum)
            import coder.internal.polyshapeHelper.boundaryTypeEnum; %#ok<EMIMP>
            if (bTypeEnum == boundaryTypeEnum.SolidCW)
                bType = 'cw';
            elseif (bTypeEnum == boundaryTypeEnum.SolidCCW)
                bType = 'ccw';
            elseif (bTypeEnum ~= boundaryTypeEnum.Invalid)
                % Boundary type was auto, let MATLAB polyshape figure out
                % the correct type
                bType = 'auto';
            else
                % This shouldn't be hit, code coverage.
                coder.internal.error('Coder:builtins:Explicit', ...
                    'Internal Error: Generated polyshape object is invalid.');
            end
        end

    end


    methods (Static, Access = private)

        %error if pshape is a vector
        function checkScalar(pshape)
            coder.internal.assert(isa(pshape, 'coder.internal.polyshape'), ...
                'MATLAB:polyshape:polyshapeTypeError');
            coder.internal.assert(isscalar(pshape), ...
                'MATLAB:polyshape:scalarPolyshapeError')
        end

        %check consistency: if P is a vector, does not allow index array
        function checkConsistency(P, num_args)
            coder.internal.errorIf(num_args == 2 && ~isscalar(P), ...
                'MATLAB:polyshape:noIndexArrayError');
        end

        %check if shape is empty
        function checkEmpty(P)
            coder.internal.errorIf(P.isEmptyShape, ...
                'MATLAB:polyshape:emptyPolyshapeError');
        end

        % input array of polyshape
        % modify when array of objects support is added to coder.
        function n = checkArray(P)
            coder.internal.assert(isa(P, 'coder.internal.polyshape'), ...
                'MATLAB:polyshape:polyshapeTypeError');
            n = size(P);
        end

        %several methods take a scalar as an input argument
        function out = checkScalarValue(value, error_id)
            coder.internal.assert(isnumeric(value) && isscalar(value) ...
                && ~issparse(value), error_id);

            coder.internal.assert(isfinite(value) && isreal(value) ...
                && ~isnan(value), error_id);

            out = double(value);
        end

        %several methods takes an index vector as an input argument
        function II = checkIndex(pshape, I)
            Lo = 1;
            Hi = numboundaries(pshape);

            if coder.target('MATLAB')
                % This check is invoked in MATLAB only during marshalling.
                % There is no need to check the validity of the index.
                II = I;
                return
            end

            %error if NaN, Inf, complex, char, sparse, empty
            coder.internal.assert(isnumeric(I) && isreal(I) && isvector(I) && allfinite(I), ...
                'Coder:toolbox:PolyIndexError');
            coder.internal.errorIf(issparse(I) || length(I) < 1, 'Coder:toolbox:PolyIndexError');

            II = double(floor(I));
            
            coder.internal.assert(coder.internal.vAllOrAny('all', II==I, @(x)(logical(x)), true), ...
                'Coder:toolbox:PolyIndexError');

            tf = coder.internal.vAllOrAny('all', II, @(x)x >= Lo, true) && ...
                coder.internal.vAllOrAny('all', II, @(x)x <= Hi, true);

            coder.internal.assert(tf, 'MATLAB:polyshape:indexError', Hi);
        end

        [X, Y, type_con, simplify, collinear] = checkInput(varargin)

        [X, Y, xy2input, next_arg] = getXY(varargin)

        [X, Y, next_arg] = getXYcell(varargin)

        collinear = parseCollinear(varargin)

        collinear = checkCollinear(next_arg)

        [Xout, Yout] = checkPointArray(param, varargin)

        [has_clip, collinear] = parseIntersectUnionArgs(clipCanBeLine, varargin)

        [direction, criterion, refPoint] = checkSortInput(varargin)

    end

    methods

        function varargout = sortregions(varargin) %#ok<*STOUT>
            coder.internal.errorIf(true, 'Coder:toolbox:PolyUnsupportedMethod','sortregions');
        end

        function varargout = triangulation(varargin)
            coder.internal.errorIf(true, 'Coder:toolbox:PolyUnsupportedMethod','triangulation');
        end

        function varargout = holes(varargin)
            coder.internal.errorIf(true, 'Coder:toolbox:PolyUnsupportedMethod','holes');
        end

        function varargout = plot(varargin)
            coder.internal.errorIf(true, 'Coder:toolbox:PolyUnsupportedMethod','plot');
        end

        function varargout = regions(varargin)
            coder.internal.errorIf(true, 'Coder:toolbox:PolyUnsupportedMethod','regions');
        end
    end

    methods (Static, Access = public, Hidden = true)
        function name = matlabCodegenUserReadableName
            % Make this look like a polyshape in the codegen report
            name = 'polyshape';
        end
    end

end

% LocalWords:  polyshape's pts Assgn Func polyshapes pshape polybuffer rmslivers sortregions
