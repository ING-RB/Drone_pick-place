classdef scatteredInterpolant < matlab.mixin.internal.indexing.Paren

% scatteredInterpolant implementation for code generation.

%   Copyright 2024 The MathWorks, Inc.
%#codegen
    properties(Hidden=true, Access=private)
        sampleVal
        delTri
        bndryGradients
        validInterpolant
        interpID
        extrapID
    end

    properties(Dependent)
        Points
        Values
        Method
        ExtrapolationMethod
    end

    methods
        %% Get Methods
        function val = get.Values(obj)
            val = obj.sampleVal;
        end

        function pts = get.Points(obj)
            pts = (obj.delTri.thePoints)';
        end

        function eMethod = get.ExtrapolationMethod(obj)
            eMethod = coder.internal.interpolate.MethodIDToString(obj.extrapMethodID);
        end

        function iMethod = get.Method(obj)
            iMethod = coder.internal.interpolate.MethodIDToString(obj.interpMethodID);
        end

        %% Set Methods
        function obj = set.Values(obj, v)
            coder.internal.scatteredInterpolant.validateDataValues(v);
            obj.validInterpolant = false; % invalidate Interpolant
            obj.sampleVal = v;
            if (size(v,1)==obj.delTri.numPts) && ...
                          (obj.extrapID == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                           (obj.extrapID == coder.internal.interpolate.interpMethodsEnum.BOUNDARY && ...
                           obj.interpID ~= coder.internal.interpolate.interpMethodsEnum.NEAREST))
                % The new value set is valid for the existing point set,
                % recompute the boundary gradients.
                [obj.bndryGradients, obj.delTri] = ...
                    coder.internal.scatteredInterpAPI.computeBoundaryGradients( ...
                    obj.sampleVal, obj.delTri);
                obj.validInterpolant = true;
            end
        end

        function obj = set.Points(obj, pts)
            coder.internal.scatteredInterpolant.validateDataPoints(pts);
            obj.validInterpolant = false; % invalidate Interpolant
            obj.delTri = obj.delTri.setPoints(pts); % This call will generate a new delaunay triangulation.
            if (obj.extrapID == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                (obj.extrapID == coder.internal.interpolate.interpMethodsEnum.BOUNDARY && ...
                obj.interpID ~= coder.internal.interpolate.interpMethodsEnum.NEAREST))
                % Redo caching if the extrapolation method requires it.
                obj.delTri = obj.delTri.extractConvexHullOfDelaunayTriangulation();
                obj.delTri = obj.delTri.cacheTriangulationOfConvexHull();
                if (size(obj.sampleVal,1)==obj.delTri.numPts)
                    % The existing value set is valid for the new point set, redo caching and
                    % compute gradients.
                    [obj.bndryGradients, obj.delTri] = ...
                        coder.internal.scatteredInterpAPI.computeBoundaryGradients( ...
                        obj.sampleVal, obj.delTri);
                    obj.validInterpolant = true;
                end
            end
        end

        function obj = set.Method(obj, ~)
            coder.internal.assert(false, 'Coder:toolbox:CannotUseSetOnMethod');
        end

        function obj = set.ExtrapolationMethod(obj, ~)
            coder.internal.assert(false, 'Coder:toolbox:CannotUseSetOnMethod');
        end

        %% Interpolation query call %%
        Vq = parenReference(obj, varargin);
        Vq = evalScatteredData(obj, interpDim, Xq, numQueries, Vq);
        Vq = evalGriddedData(obj, interpDim, Xq, numQueries, Vq);

        %% Constructor
        function obj = scatteredInterpolant(varargin)
        % sizes are inherited from user inputs, empty
        % interpolants aren't allowed for codegen.
            coder.internal.assert(nargin>=1,'Coder:polyfun:EmptyInteroplantObjectErr');

            % 3p/Qhull needs malloc
            coder.internal.assert(coder.areUnboundedVariableSizedArraysSupported, ...
                                  'Coder:toolbox:FuncNeedsDynamic', 'scatteredInterpolant');

            % narg is the number of numeric inputs
            [narg, interpID, extrapID] = ...
                coder.internal.scatteredInterpolant.extractNargsAndMethods(varargin{:});

            obj.interpID = interpID;
            obj.extrapID = extrapID;

            % Validate number of numeric inputs
            posOfVal = coder.const(narg); % This has to be constant, using coder.const to force const folding.
            coder.internal.assert(posOfVal>=2 && posOfVal<=4, ...
                                  'MATLAB:mathcgeo_catalog:BadNumArgsInterpErrId');

            % The last double input is the sample values.
            vals = varargin{posOfVal};
            % Validate sample value
            coder.internal.scatteredInterpolant.validateDataValues(vals);

            numDataArr = posOfVal - 1;
            if (numDataArr == 1)
                % Matrix input, scatteredInterpolant(P,v)
                coder.internal.scatteredInterpolant.validateDataPoints(varargin{1});

                [numPts, numDims] = size(varargin{1});

                coder.internal.assert(size(vals,1) == numPts, 'MATLAB:mathcgeo_catalog:NumpNumvErrId');
                coder.internal.assert(numDims==2, ...
                                      'Coder:polyfun:scatteredInterp2DOnly'); % First pass supports only 2D inputs
                obj.delTri = coder.internal.delaunayTriangulation(numPts, numDims, numDataArr, varargin{1});
            else
                % Vector inputs, scatteredInterpolant(x,y,v) or scatteredInterpolant(x,y,z,v)

                % Validate 2D inputs
                coder.internal.scatteredInterpolant.validateDataPoints(varargin{1});
                coder.internal.scatteredInterpolant.validateDataPoints(varargin{2});
                % Sample points need to be column vectors
                coder.internal.assert(iscolumn(varargin{1}) && iscolumn(varargin{2}), ...
                                      'MATLAB:mathcgeo_catalog:NonColVecInpPtsErrId');

                numDims = 2;
                numPts = size(varargin{1},1);
                coder.internal.assert(numPts == size(varargin{2},1), 'MATLAB:mathcgeo_catalog:MixDimDataPtCoordsErrId');

                coder.internal.assert(numDataArr==2, ...
                                      'Coder:polyfun:scatteredInterp2DOnly'); % First pass supports only 2D inputs
                coder.internal.assert(size(vals,1) == numPts, 'MATLAB:mathcgeo_catalog:NumpNumvErrId');
                obj.delTri = coder.internal.delaunayTriangulation(numPts, numDims, numDataArr, varargin{1}, varargin{2});
            end

            if obj.delTri.mergeDuplicatePoints
                obj.sampleVal = coder.internal.scatteredInterpolant.averageValuesForDuplicates(obj.delTri, vals);
            else
                obj.sampleVal = vals;
            end

            if extrapID == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                         (extrapID == coder.internal.interpolate.interpMethodsEnum.BOUNDARY && ...
                         interpID ~= coder.internal.interpolate.interpMethodsEnum.NEAREST)
                obj.delTri = obj.delTri.extractConvexHullOfDelaunayTriangulation();
                obj.delTri = obj.delTri.cacheTriangulationOfConvexHull();
                [obj.bndryGradients, obj.delTri] = coder.internal.scatteredInterpAPI.computeBoundaryGradients( ...
                    obj.sampleVal, obj.delTri);
            else
                obj.bndryGradients = zeros(1,0,'double');
            end
            obj.validInterpolant = true;
        end
    end

    methods(Static, Access=private, Hidden=true)

        %% Make methods nontunable
        function props = matlabCodegenNontunableProperties(~)
            props = {'interpID', 'extrapID'};
        end

        %% Validation methods
        % Explicitily validating the input, as opposed to using FAV, since MATLAB has a custom catalog of errors.
        function validateDataValues(v)
            coder.internal.errorIf(issparse(v), 'MATLAB:mathcgeo_catalog:SparseInterpValuesErrId');
            coder.internal.errorIf(iscell(v), 'MATLAB:mathcgeo_catalog:CellOfValuesErrId');
            coder.internal.assert(isa(v, 'double'), 'MATLAB:mathcgeo_catalog:NonDoubleValuesErrId');
            coder.internal.errorIf(isempty(v), 'MATLAB:mathcgeo_catalog:ValueBadDimErrId');
        end

        function validateDataPoints(inPts)
            coder.inline('always') % Inlining, as the finite checks are the only ones that might be retained at runtime.
            coder.internal.errorIf(issparse(inPts), 'MATLAB:mathcgeo_catalog:SparseDataPtErrId');
            coder.internal.assert(isreal(inPts), 'MATLAB:mathcgeo_catalog:ComplexDataPointErrId');
            coder.internal.assert(isa(inPts, 'double'), 'MATLAB:mathcgeo_catalog:NonDblInpPtsErrId');
            coder.internal.assert(allfinite(inPts), 'MATLAB:mathcgeo_catalog:NonFiniteInputPtsErrId'); % Short circuit ? these inputs might be large
            coder.internal.errorIf(isempty(inPts), 'MATLAB:mathcgeo_catalog:EmptyInpPtsErrId');
        end

        function validateQueryPoints(inPts)
            coder.inline('always') % Inlining, as the finite checks are the only ones that might be retained at runtime.
            coder.internal.assert(isnumeric(inPts), 'MATLAB:mathcgeo_catalog:BadArgInterpEvalErrId');
            coder.internal.errorIf(issparse(inPts), 'MATLAB:mathcgeo_catalog:SparseDataPtErrId');
            coder.internal.assert(isreal(inPts), 'MATLAB:mathcgeo_catalog:ComplexDataPointErrId');
            coder.internal.assert(isa(inPts, 'double'), 'MATLAB:mathcgeo_catalog:NonDblInpPtsErrId');
        end

        [narg, interpID, extrapID] = extractNargsAndMethods(varargin);
        [interpID, extrapID] = validateInterpExtrapMethod(varargin);
        [isQryVtx, bc] = solveBarycentricEqs(wkspc, bc, nd);
        averagedVal = averageValuesForDuplicates(delTriObj, inputVal);
    end

    methods (Static, Access=public, Hidden=true)
        function MLObj = matlabCodegenFromRedirected(~) %#ok<STOUT>
            coder.internal.errorIf(true, 'Coder:polyfun:scatteredInterpolantCannotBeEntryPoint');
        end

        function coderObj = matlabCodegenToRedirected(~) %#ok<STOUT>
            coder.internal.errorIf(true, 'Coder:polyfun:scatteredInterpolantCannotBeEntryPoint');
        end

        function name = matlabCodegenUserReadableName
        % Make this look like a scatteredInterpolant in the codegen report
            name = 'scatteredInterpolant';
        end
    end

end
