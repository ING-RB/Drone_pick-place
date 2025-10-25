function Vq = parenReference(obj, varargin)
%#codegen

narginchk(2, 4);
coder.internal.assert(obj.validInterpolant, 'MATLAB:mathcgeo_catalog:InterpOutOfSyncErrId');
interpDim = obj.delTri.numSpatialDim();

if isscalar(varargin)
    % Parsing gridded(cell) and matrix queries
    queryPoints = varargin{1};
    if iscell(queryPoints)
        numGridVectors = numel(queryPoints);
        numQueries = coder.internal.indexInt(1);
        % Validation
        coder.internal.assert(numGridVectors == obj.delTri.numSpatialDim, ...
                              'MATLAB:mathcgeo_catalog:BadArgInterpEvalErrId');
        
        coder.unroll(coder.internal.isConst(numGridVectors));
        for i=1:numGridVectors
            % MATLAB allows any dimension to contain the data.
            % eg. obj({reshape(1:3,1,1,3),reshape(1:3,1,1,3)}) and
            % obj({1:3,1:3}) generate the same grid.
            % In Coder, we restrict inputs to vectors.
            coder.internal.assert(isvector(queryPoints{i}), ...
                                  'MATLAB:mathcgeo_catalog:NonVecCompVecErrId');
            coder.internal.scatteredInterpolant.validateQueryPoints(queryPoints{i});
            numQueries = numQueries*coder.internal.indexInt( ...
                numel(queryPoints{i})); % Accumulate number of queries.
        end
        % Interpolation call
        Vq = obj.evalGriddedData(interpDim, queryPoints, numQueries);
    else
        % Validation
        coder.internal.errorIf(interpDim ~= coder.internal.prodsize(queryPoints,'above',1), ...
                               'MATLAB:mathcgeo_catalog:BadArgInterpEvalErrId');
        coder.internal.scatteredInterpolant.validateQueryPoints(queryPoints);
        % Interpolation call
        numQueries = coder.internal.indexInt(size(varargin{1}, 1));
        Vq = obj.evalScatteredData(interpDim, queryPoints, numQueries);
    end

else
    % Parse scattered array queries.
    coder.internal.assert(numel(varargin)==2, 'Coder:polyfun:scatteredInterp2DOnly');
    % Validation
    coder.unroll()
    for i = 1:numel(varargin)
        coder.internal.scatteredInterpolant.validateQueryPoints(varargin{i});
    end
    coder.internal.assert(isequal(size(varargin{1}), size(varargin{2})), 'MATLAB:mathcgeo_catalog:InputMixSizeErrId');
    % Interpolation call
    numQueries = coder.internal.indexInt(numel(varargin{1}));
    Vq = obj.evalScatteredData(interpDim, varargin, numQueries);
end
