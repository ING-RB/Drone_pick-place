classdef griddedInterpolant < matlab.mixin.internal.indexing.Paren
    % MATLAB implementation of griddedInterpolant for code generation.

    %   Copyright 2022-2024 The MathWorks, Inc.

    %#codegen


    %% Properties
    properties(Dependent)      
        Method              % dummy property to get appropriate character vector for interp
        ExtrapolationMethod % dummy property to get appropriate character vector for extrap
        GridVectors         % dummy property returns gridVectors_, used for 
                            % set/get methods
        Values              % dummy property returns gridValues, used for 
                            % set/get methods
    end

    properties(Access=private)
        interpMethodID      % Stores Method ID for interpolation method
        extrapMethodID      % Stores Method ID for extrapolation method
        gridVectors_        % Private storage of grid vectors,
                            % stored as cell array of vector {[],[],[]...}
        gridValues          % stored as n-d array []
        validState          % logical storing state of object
        ppStruct1DInterp    % Stores 1D pp struct for interpolation.
        ppStruct1DExtrap    % Stores 1D pp struct for extrapolation.
        interpToUseForCubic % Interpolation to be used when input is 'cubic',
                            % can be 'linear', 'spline' or 'cubic'.
        extrapToUseForCubic % Extrapolation to be used when input is 'cubic',
                            % can be 'linear', 'spline' or 'cubic'.                         
        splineCoefsND       % Stores ND spline coefficients.
    end
    
    methods
    %% Interpolation query call %%
        function Vq = parenReference(obj, varargin)
        % function for interpolation query call        
               
            if ~obj.validState
                % Error out if object is in an invalid state
                coder.internal.griddedInterpolant.parseGridValues(obj.gridValues, ...
                    numel(obj.gridVectors_));
                coder.internal.griddedInterpolant.parseGridVectorsFromCell(obj.gridVectors_, ...
                    obj.gridValues, true);
            end

            coder.internal.errorIf((obj.interpMethodID == coder.internal.interpolate.interpMethodsEnum.MAKIMA || ...
                obj.extrapMethodID == coder.internal.interpolate.interpMethodsEnum.MAKIMA) && ...
                 ~isempty(obj.gridVectors_) && ~isscalar(obj.gridVectors_), 'Coder:toolbox:gInterpNdUnsupportedMethod');

            coder.internal.assert((isscalar(varargin)) || ...
                numel(varargin) == numel(obj.gridVectors_), ...
                'MATLAB:griddedInterpolant:BadArgInterpEvalErrId', numel(obj.gridVectors_));

            n = coder.internal.griddedInterpolant.getGridDim(obj.gridValues, ...
                numel(obj.gridVectors_));

            if(isscalar(varargin))
                % Parsing 1-D and cell array queries
                queryPoints = varargin{1};
                
                if iscell(queryPoints)
                    coder.internal.griddedInterpolant.checkQueryGridVectorsCountAndType( ...
                        queryPoints, obj.gridValues, n, true);
                    
                    if isvector(obj.gridValues)
                        Vq = zeros( numel(queryPoints{1}),1,'like', ...
                            coder.internal.interpolate.interpNaN(obj.gridValues));
                    else
                        
                        dimsVq = size(obj.gridValues);
                        for i = 1:n
                            Xi = queryPoints{i};
                            coder.internal.assert(isempty(Xi) || isvector(Xi), ...
                                'MATLAB:griddedInterpolant:NonVecCompVecErrId')
                            dimsVq(i) = numel(Xi);
                        end
                        
                        Vq = zeros(dimsVq, 'like', ...
                            coder.internal.interpolate.interpNaN(obj.gridValues));
        
                    end
                   
                    if(isscalar(obj.gridVectors_))
                        Vq = EvaluatorSwitch(obj, queryPoints{1}, Vq);
                    else
                        Vq = EvaluatorSwitchNDCell(obj, queryPoints);
                    end
                    
                else
        
                    coder.internal.griddedInterpolant.checkFullRealCoords(queryPoints);
                    
                    if n==1
                                
                        if (isvector(obj.gridValues))
                            dimsq = size(queryPoints);
                            Vq = zeros(dimsq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        else
                            dimsVq = size(obj.gridValues);
                            dimsVq(1) = numel(queryPoints);
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        end
        
                    else
                        coder.internal.assert( (ismatrix(queryPoints)) ...
                            && (size(queryPoints,2)==n), ...
                          'MATLAB:griddedInterpolant:BadArgInterpEvalErrId',n)
                        
                        ndimsV = ndims(obj.gridValues);
                        
                        if (n == ndimsV )
                            dimsVq = zeros(1,2);
                            dimsVq(1) = size(queryPoints,1);
                            dimsVq(2) = 1;
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        else
                            dimsVq = size(obj.gridValues);
                            dimsVq(1:n) = 1;
                            dimsVq(1) = size(queryPoints,1);
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        end
                    end

                    if(isscalar(obj.gridVectors_))
                        Vq = EvaluatorSwitch(obj, queryPoints, Vq);
                    else
                        Vq = EvaluatorSwitchNDScatter(obj, queryPoints, Vq);
                    end
                end
        
            elseif numel(varargin) == n
                % Parsing of N-D queries of non-cell array type.
                
                coder.internal.griddedInterpolant.checkGridArraysType(varargin, n, obj.gridValues, true);
        
                Xq0 = varargin{1};
                for i = 1:numel(varargin)
                    coder.internal.assert(isequal(size(varargin{i}), size(Xq0)), ...
                        'MATLAB:griddedInterpolant:InputMixSizeErrId');
                end
        
                ndimsV = coder.internal.ndims(obj.gridValues);
                dimsV = size(obj.gridValues);
        
                ndimsXq = coder.internal.ndims(Xq0);
                dimsXq = size(Xq0);
        
                if isempty(Xq0)
                    if n==ndimsV
                        Vq = zeros(dimsXq, 'like', ...
                            coder.internal.interpolate.interpNaN(obj.gridValues));
                    else
                        if (ndimsXq == n)
                            dimsVq = dimsV(1:ndimsV);
                            dimsVq(1:ndimsXq) =  dimsXq(1:ndimsXq);
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        elseif (ndimsXq < n)
                            dimsVq = dimsV(1:ndimsV);
                            dimsVq(1:n) = 1;
                            dimsVq(1:ndimsXq) =  dimsXq(1:ndimsXq);
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        else
                            dimsVq = dimsV(1:ndimsV);
                            dimsVq(1:n) = 1;
                            dimsVq(1) = numel(Xq0);
                            Vq = zeros(dimsVq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues));
                        end
                    end
                else
                    
                    % Adding a const flag to ensure const size output
                    constIsndgrid = coder.internal.isConstFalse(isvector(varargin{1}));
                    isndgrid = false;
                    if constIsndgrid
                        [Xq, isndgrid] = coder.internal.griddedInterpolant.createGridVectorsFromNDGrid(varargin, n); 
                    end
                    if constIsndgrid && isndgrid
                        Vq = EvaluatorSwitchNDCell(obj, Xq);
                    else
                        if constIsndgrid
                            % can be a meshgrid only if input is not a
                            % vector
                            if coder.internal.griddedInterpolant.ismeshgrid(varargin, n)
                                if n==2
                                    coder.internal.warning('MATLAB:griddedInterpolant:MeshgridEval2DWarnId');
                                else
                                    coder.internal.warning('MATLAB:griddedInterpolant:MeshgridEval3DWarnId');
                                end
                            end
                        end
                        
                        if n==ndimsV
                            Vq = coder.nullcopy(zeros(dimsXq, 'like', ...
                                coder.internal.interpolate.interpNaN(obj.gridValues)));
                        else
                            if ndimsXq == n
                                dimsVq = dimsV(1:ndimsV);
                                dimsVq(1:ndimsXq) =  dimsXq(1:ndimsXq);
                                Vq = coder.nullcopy(zeros(dimsVq, 'like', ...
                                    obj.gridValues));
                            elseif ndimsXq < n
                                dimsVq = dimsV(1:ndimsV);
                                dimsVq(1:n) = 1;
                                dimsVq(1:ndimsXq) =  dimsXq(1:ndimsXq);
                                Vq = coder.nullcopy(zeros(dimsVq, 'like', ...
                                    obj.gridValues));
                            else
                                dimsVq = dimsV(1:ndimsV);
                                dimsVq(1:n) = 1;
                                dimsVq(1) = numel(Xq0);
                                Vq = coder.nullcopy(zeros(dimsVq, 'like', ...
                                    obj.gridValues));
                            end
                        end
                        
                        Vq = EvaluatorSwitchNDScatter(obj, varargin, Vq);
                        
                    end
                end
            else
                coder.internal.error('MATLAB:griddedInterpolant:BadArgInterpEvalErrId', n);        
            end

        end
    %% Setter Methods %%

        function obj = set.GridVectors(obj, X)
            
            obj = setAndTestGridVector(obj,X);
            
        end

        function obj = setAndTestGridVector(obj, X)
            
            obj.gridVectors_ = X;

            METHOD = obj.interpMethodID;
            EXTRAPp = obj.extrapMethodID;
            
            [METHOD, EXTRAPp] = coder.internal.griddedInterpolant.validateMethodDependingOnGrid( ...
                obj.gridVectors_, false, METHOD, EXTRAPp);
            obj.interpToUseForCubic = METHOD;
            obj.extrapToUseForCubic = EXTRAPp;

            % set validity flag, doesn't error out for invalid. error occurs
            % at query time.
            obj.validState = coder.internal.griddedInterpolant.parseGridVectorsFromCell(obj.gridVectors_, ...
                obj.gridValues, true, false);
            
            if obj.validState
                obj = generateppStruct(obj);
            end
        end

        function obj = set.Values(obj, V)
            obj = obj.updateVals(V);
        end

        function obj = updateVals(obj, V)
            
            % testing to ensure input is of proper type
            % calling this to ensure that error matches MATLAB as much as
            % possible.
            coder.internal.griddedInterpolant.parseGridValues(V, ...
                numel(obj.gridVectors_));

            obj.gridValues = V;
            
            % set validity flag, doesn't error out for invalid. error occurs
            % at query time.
            obj.validState = coder.internal.griddedInterpolant.parseGridVectorsFromCell(obj.gridVectors_, ...
                obj.gridValues, true, false);
            
            if obj.validState
                obj = obj.generateppStruct();
            end
        end

        function obj = set.Method(obj, ~)
            coder.internal.assert(false, 'Coder:toolbox:CannotUseSetOnMethod');
        end

        function obj = set.ExtrapolationMethod(obj, ~)
            coder.internal.assert(false, 'Coder:toolbox:CannotUseSetOnMethod');
        end
        
    %% Getter Methods %%
        function gv = get.GridVectors(obj)
            gv = obj.gridVectors_;
        end

        function v = get.Values(obj)
            v = obj.gridValues;
        end

        function eMethod = get.ExtrapolationMethod(obj)
            if obj.extrapMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC
                eMethod = coder.internal.interpolate.MethodIDToString(obj.extrapToUseForCubic);
            else
                eMethod = coder.internal.interpolate.MethodIDToString(obj.extrapMethodID);
            end
        end

        function iMethod = get.Method(obj)
            if obj.interpMethodID == coder.internal.interpolate.interpMethodsEnum.CUBIC
                iMethod = coder.internal.interpolate.MethodIDToString(obj.interpToUseForCubic);
            else
                iMethod = coder.internal.interpolate.MethodIDToString(obj.interpMethodID);
            end
        end
    %% Constructor %%
        function obj = griddedInterpolant(varargin)
            
            % sizes are inherited from user inputs, empty
            % interpolants aren't allowed for codegen.
            coder.internal.assert(nargin>=1,'Coder:toolbox:EmptyInteroplantObjectErr');
        
            [NARG,METHOD,EXTRAPp] = coder.internal.griddedInterpolant.methodAndExtrapP(varargin{:});
            
            isCellX = coder.const(iscell(varargin{1}));
            offsetCellX = coder.internal.indexInt(isCellX && (nargin > 1));
            offsetCellX = offsetCellX + 1;
            firstNonFloat = coder.internal.indexInt(NARG+1);
            
            for i = offsetCellX:NARG
                if(~isfloat(varargin{i}))
                    firstNonFloat = i;
                    break;
                end
            end
            
            coder.internal.assert(firstNonFloat > offsetCellX, ...
                'MATLAB:griddedInterpolant:NonFloatValuesErrId');
            coder.internal.assert(firstNonFloat > NARG, ...
                'MATLAB:griddedInterpolant:NonFloatValuesErrId');

            numGridVectors = coder.const(firstNonFloat - 2);
            V = varargin{numGridVectors+1};

            if(isCellX)
                
                coder.internal.assert(numGridVectors <= 1, ...
                    'MATLAB:griddedInterpolant:SampleValuesNotSecond')
                
                coder.internal.griddedInterpolant.parseGridValues(V, numel(varargin{1}));
                obj.gridValues = V;

                coder.internal.griddedInterpolant.parseGridVectorsFromCell(varargin{1}, V, true);
                gridVectors_ = varargin{1};
                
                defaultX = coder.const(0);
            else

                coder.internal.griddedInterpolant.parseGridValues(V, numGridVectors);
                obj.gridValues = V;
                
                if (numGridVectors > 0)
                    gridVectors_ = coder.internal.griddedInterpolant.parseGridVectorsFromNDGrid(varargin, numGridVectors, V);
                    defaultX = coder.const(0);
                else
                    gridVectors_ = coder.internal.griddedInterpolant.createGridVectorsDefault(obj.gridValues);
                    defaultX = coder.const(1);
                end

            end
            
            obj.gridVectors_ = gridVectors_;
            
            obj.interpMethodID = METHOD;
            obj.extrapMethodID = EXTRAPp;

            % Validates interp/extrap methods and 
            % assigns alternate methods for cubic if required.
            obj = validateInterpExtrapMethod(obj, obj.interpMethodID, obj.extrapMethodID, defaultX);
            
            obj = generateppStruct(obj);
            obj.validState = true;
            
        end
    end

    methods(Access=private)
    %% Method Assignment %%
        function obj = validateInterpExtrapMethod(obj, METHOD, EXTRAPp, defaultX)
            % main function that validates and changes the method based on grid vectors
            
            [METHOD, EXTRAPp] = coder.internal.griddedInterpolant.validateMethodDependingOnGrid(obj.gridVectors_, ...
                defaultX, METHOD, EXTRAPp);
            obj.interpToUseForCubic = METHOD;
            obj.extrapToUseForCubic = EXTRAPp;
            
        end
    %% ppStruct Creation %%
        obj = generateppStruct(obj);
    end

    %% Codegen Redirects %%
    methods (Static, Access = public, Hidden = true)
        
        function props = matlabCodegenNontunableProperties(~)
            % Create NontunableProperties
            props = {'interpMethodID', 'extrapMethodID'};
        end

        function MLObj = matlabCodegenFromRedirected(coderObj)
            % Function to return object of MATLAB griddedInterpolant class
            % at exit.
            MLObj = griddedInterpolant(coderObj.GridVectors, coderObj.Values, ...
                coderObj.Method, coderObj.ExtrapolationMethod);
        end

        function coderObj = matlabCodegenToRedirected(MLObj)
            % Function to convert object of MATLAB griddedInterpolant to 
            % coder object at entry point.
            coderObj = coder.internal.griddedInterpolant(MLObj.GridVectors, ...
                MLObj.Values, MLObj.Method, MLObj.ExtrapolationMethod); 
        end

        function name = matlabCodegenUserReadableName
            % Make this look like a griddedInterpolant in the codegen report
            name = 'griddedInterpolant';
        end
    end

    %% Validation and Parsing Methods %%
    methods (Static, Access=private)

        n = getGridDim(gridValues, numGridVectors)
%--------------------------------------------------------------------------
        parseGridValuesTypes(gridValues)
%--------------------------------------------------------------------------
        parseGridValues(gridValues, numGridVectors)
%--------------------------------------------------------------------------
        checkFullRealCoords(A)
%--------------------------------------------------------------------------
        validityFlag = checkGridVectorsCount(gridVectorsCellInput, ~, gridDim, ...
            matchAgainstGridValues, errorOut)
%--------------------------------------------------------------------------
        checkGridVectorsType(gridVectorsCellInput)
%--------------------------------------------------------------------------
        validityFlag = checkQueryGridVectorsCountAndType(gridVectorsCellInput, gridValues, ...
            gridDim, matchAgainstGridValues, errorOut)
%--------------------------------------------------------------------------
        validityFlag = checkGridVectorsCountAndType(gridVectorsCellInput, gridValues, ...
            matchAgainstGridValues, errorOut)
%--------------------------------------------------------------------------
        validityFlag = checkGridVectorsSize(gridVectorsCellInput, gridValues, ...
            matchAgainstGridValues, errorOut)
%--------------------------------------------------------------------------
        hasStrictlyIncreasingFinites(A)
%--------------------------------------------------------------------------
        checkStrictlyIncreasingFinites(gridVectors)           
%--------------------------------------------------------------------------
        validityFlag = parseGridVectorsFromCell(gridVectorsCellInput, gridValues, ...
            matchAgainstGridValues, errorOut)
%--------------------------------------------------------------------------
        checkGridArraysType(gridArrays, gridDim, ~, useQueryErrorMsg)
%--------------------------------------------------------------------------
        Xi = createOneGridVector(numel, clsID, fillWithDefaultGridCoordinates) 
%--------------------------------------------------------------------------
        [xivec,b] = extractOneGridVectorCheckNDGridness(Xi, stride, ...
            prodUpperDims, xivecNumel)
%--------------------------------------------------------------------------
        [X, isndgrid] = createGridVectorsFromNDGrid(ndgrid, n)
%--------------------------------------------------------------------------
        ismesh = ismeshgrid(ndgrid, n)
%--------------------------------------------------------------------------
        X = parseGridVectorsFromNDGrid(ndgrid, nd, gridValues)
%--------------------------------------------------------------------------
        X = createGridVectorsDefault(gridValues)
%--------------------------------------------------------------------------
        methodCheck(iemethod, doInterp)
%--------------------------------------------------------------------------
        parseInterpExtrapMethod(A, doInterp)
%--------------------------------------------------------------------------
        b = isUniformVector(G, len, cls)
%--------------------------------------------------------------------------
        info = checkIfGridSupportsCubic(gridVectors, defaultVectors)
%--------------------------------------------------------------------------
        [METHOD, EXTRAPp] = validateMethodDependingOnGrid(gridVectors, ...
            defaultVectors, METHOD, EXTRAPp)                
%--------------------------------------------------------------------------        
        [NARG,METHOD,EXTRAPp] = methodAndExtrapP(varargin)
%--------------------------------------------------------------------------
        tf = ppStructMethods(methodID);
    end

    %% Dispatch methods %%
    methods(Access=private)
        % 1D Dispatch
        Vq = EvaluatorSwitch(obj, Xq, Vq)

        % nD cell array Dispatch
        Vq = EvaluatorSwitchNDCell(obj, XqCell)

        % nD scattered query Dispatch
        Vq = EvaluatorSwitchNDScatter(obj, Xq, Vq)

    end
    
end

% LocalWords:  extrap Vec DWarn interpolants Interoplant
