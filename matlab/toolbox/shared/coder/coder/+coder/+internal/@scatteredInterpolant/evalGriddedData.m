function Vq = evalGriddedData(obj, interpDim, Xq, numQueries)
% Evaluate interpolant for gridded queries

%   Copyright 2024 The MathWorks, Inc.

%#codegen

% Create function handles for extrap method
m = obj.interpID;
mExtrap = obj.extrapID;
if mExtrap == coder.internal.interpolate.interpMethodsEnum.NEAREST
    extrapFuncHandle = @(x,y,nVal,nPts)obj.nearestExtrapolationKernel(x,y,nVal,nPts);
elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.LINEAR
    extrapFuncHandle = @(x,y,nVal,nPts)obj.linearExtrapolationKernel(x,y,nVal,nPts);
elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.NONE
    extrapFuncHandle = @(x,y,nVal,nPts)obj.noneExtrapolationKernel(x,y,nVal,nPts);
elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.BOUNDARY
    if m == coder.internal.interpolate.interpMethodsEnum.NEAREST
        extrapFuncHandle = @(x,y,nVal,nPts)obj.nearestExtrapolationKernel(x,y,nVal,nPts);
    else
        extrapFuncHandle = @(x,y,nVal,nPts)obj.boundaryExtrapolationKernel(x,y,nVal,nPts);
    end
else
    % This will never be hit, added for completeness
    coder.internal.error('Coder:builtins:Explicit', 'Internal Error');
end

% Shape of nd grid formed from the grid vectors
dimsXq = dimsForGriddedQuery(interpDim, Xq);

% Allocate memory for output
if iscolumn(obj.sampleVal)
    dimsVq = dimsXq;
    Vq = coder.nullcopy(zeros(dimsVq, 'like', obj.sampleVal));
else
    dimsV = size(obj.sampleVal);
    dimsVq = [dimsXq, dimsV(2:end)];
    Vq = coder.nullcopy(zeros(dimsVq, 'like', obj.sampleVal));
end

% Number of values to fill for multi-valued interpolations.
nFuncVal = coder.internal.prodsize(obj.sampleVal, 'above', 1);
% Memory to store out for a single query point.
singleQueryOut = coder.nullcopy(zeros(nFuncVal, 1, 'like', obj.sampleVal));
% Number of sample points.
nSamplePts = obj.delTri.numPts;

% Dispatch query and handle to extrapolation method.
for k = 1:numQueries
    % Extract single query point to interpolate.
    qp = extractQueryPoint(Xq, dimsXq, interpDim, numQueries, k);
    
    if m == coder.internal.interpolate.interpMethodsEnum.NEAREST
        singleQueryOut = obj.nearestInterpolationKernel(qp, singleQueryOut, ...
                                                        nFuncVal, nSamplePts, (m==mExtrap), extrapFuncHandle);
    elseif m == coder.internal.interpolate.interpMethodsEnum.LINEAR
        singleQueryOut = obj.linearInterpolationKernel(qp, singleQueryOut, ...
                                                       nFuncVal, nSamplePts, extrapFuncHandle);
    elseif m == coder.internal.interpolate.interpMethodsEnum.NATURAL
        singleQueryOut = obj.naturalInterpolationKernel(qp, singleQueryOut, ...
                                                        nFuncVal, nSamplePts, extrapFuncHandle);
    end
    % Insert the outputs of the single query point at the appropriate
    % indices in the larger output array.
    Vq = insertInterpolatedValues(singleQueryOut, k, numQueries, nFuncVal, Vq);
end

%--------------------------------------------------------------------------

function [qp, ndIdx] = extractQueryPoint(Xq, dimsXq, nd, nq, k)
% Extract a single query point from a grid vector input.
coder.internal.prefer_const(dimsXq, nd, nq);
assert(iscell(Xq));
qp = coder.nullcopy(zeros(1,nd,'like',Xq{1}));
ndIdx = coder.nullcopy(cell(1,nd));
[ndIdx{:}] = ind2sub(dimsXq, k);
coder.unroll()
for i=1:nd
    qp(i) = Xq{i}(ndIdx{i});
end

%--------------------------------------------------------------------------

function Vq = insertInterpolatedValues(Vtemp, qIdx, nq, nv, Vq)
% Insert the output vals of a single query point into the larger out
% matrix.
coder.inline('always');
coder.internal.prefer_const(nv);
for j = 0:nv-1
    Vq(qIdx + j*nq) = Vtemp(j+1);
end

%--------------------------------------------------------------------------

function sz = dimsForGriddedQuery(nd, Xq)
coder.inline('always')
coder.internal.prefer_const(nd);
sz = coder.nullcopy(zeros(1,nd));
for k = 1:nd
    sz(k) = numel(Xq{k});
end