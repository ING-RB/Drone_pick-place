function Vq = EvaluatorSwitchNDScatter(obj, Xq, Vq)
% Scattered Query, each query point is independently interpolated.

    %#codegen

    m = obj.interpMethodID;
    mExtrap = obj.extrapMethodID;

    nd = coder.internal.indexInt(numel(obj.gridVectors_));
    if iscell(Xq)
        nq = numel(Xq{1});
    else
        nq = size(Xq,1);
    end
    ncols = coder.internal.indexInt(coder.internal.prodsize(Vq,'above',nd));
    nrows = coder.internal.indexInt(numel(obj.gridValues)/ncols);

    V = coder.nullcopy(zeros(size(obj.gridValues, 1:nd), 'like', obj.gridValues));
    outNan = coder.const(coder.internal.interpolate.interpNaN(obj.gridValues));

    % generate order and pieces array if method is spline
    if m == coder.internal.interpolate.interpMethodsEnum.SPLINE || ...
            mExtrap == coder.internal.interpolate.interpMethodsEnum.SPLINE || ...
            m == coder.internal.interpolate.interpMethodsEnum.CUBIC || ...
            mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC
        % This can be saved as class properties, refactor.
        [ord, pcs] = coder.internal.interpolate.splineNdGetOrd(nd, obj.gridValues, obj.gridVectors_{:});
    end
    
    % Assign minima, maxima and diff of elements in each dimension.
    % Diff is used only in cubic. Generating for all methods anyway as
    % expectation is dimension of a query is not large.
    [xmin, xmax, dx] = getMinMaxOfGrid(nd, obj);
    
    % Get the index vectors needed to extract bounding box for a point from gridValues. 
    % Used in case of local interpolation methods, where, only the
    % neighbouring points contribute to the final answer.
    if m == coder.internal.interpolate.interpMethodsEnum.LINEAR || ... 
            mExtrap == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
            m == coder.internal.interpolate.interpMethodsEnum.NEAREST || ...
            mExtrap == coder.internal.interpolate.interpMethodsEnum.NEAREST || ...
            m == coder.internal.interpolate.interpMethodsEnum.CUBIC || ... 
            mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC
        [vbbidx, stride] = coder.internal.interpolate.BoundingBoxIndexArrays(V);
    end

    % extract sample values one by one from multivalued functions.
    for j = 1:ncols
            
        V = extractSampleValues(obj.gridValues, j, nrows, V);

        % create expanded val only if cubic method is being used.
        if m == coder.internal.interpolate.interpMethodsEnum.CUBIC || ...
                mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC
            
            % Allocate memory if cubic method is used.
            VV = coder.nullcopy(zeros(size(V)+2,'like',V));
            if obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC || ...
                    obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC
                % Create variable only if cubic method is invoked.
                VV = expandVal(V, VV, nd, obj.gridVectors_);
            end
        else
            % setting to 0 to ensure definition on all paths.
            % Shouldn't be accessed if cubic method isn't used.
            VV = 0;
        end

        for k = 1:nq
            qp = extractQueryPoint(Xq, nd, k);
        
            if coder.internal.interpolate.isInterpPoint(qp, nd, xmin, xmax)
                % Point is inside Bounding Box, call interpMethod
                if m == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                        m == coder.internal.interpolate.interpMethodsEnum.NEAREST
                     Vtemp = coder.internal.interpolate.interpnLocalLoopBody(nd, m, ...
                         true, outNan, vbbidx, stride, xmin, xmax, V, qp, obj.gridVectors_{:});
                elseif m == coder.internal.interpolate.interpMethodsEnum.CUBIC
                    if obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.LINEAR
                        Vtemp = coder.internal.interpolate.interpnLocalLoopBody(nd, m, ...
                         true, outNan, vbbidx, stride, xmin, xmax, V, qp, obj.gridVectors_{:});
                    elseif obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.SPLINE
                        Vtemp = coder.internal.interpolate.splineEvalNdScatter(nd, ...
                        obj.splineCoefsND, qp, ord, pcs, j, obj.gridVectors_{:});
                    else
                        assert(obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC);
                        Vtemp = coder.internal.interpolate.interpnCubicLoopBody(qp, VV, nd, ...
                            xmin, xmax, dx, true, outNan, obj.gridVectors_{:});
                    end
                elseif m == coder.internal.interpolate.interpMethodsEnum.SPLINE
                    Vtemp = coder.internal.interpolate.splineEvalNdScatter(nd, ...
                        obj.splineCoefsND, qp, ord, pcs, j, obj.gridVectors_{:});
                end
            else
                % Point is outside Bounding Box, call extrap
                if mExtrap == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                        mExtrap == coder.internal.interpolate.interpMethodsEnum.NEAREST
                    Vtemp = coder.internal.interpolate.interpnLocalLoopBody(nd, mExtrap, ...
                        true, outNan, vbbidx, stride, xmin, xmax, V, qp, obj.gridVectors_{:});
                elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC
                    if obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.LINEAR
                        Vtemp = coder.internal.interpolate.interpnLocalLoopBody(nd, mExtrap, ...
                            true, outNan, vbbidx, stride, xmin, xmax, V, qp, obj.gridVectors_{:});
                    elseif obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.SPLINE
                        Vtemp = coder.internal.interpolate.splineEvalNdScatter(nd, ...
                            obj.splineCoefsND, qp, ord, pcs, j, obj.gridVectors_{:});
                    else 
                        assert(obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC);
                        Vtemp = coder.internal.interpolate.interpnCubicLoopBody(qp, VV, nd, ...
                            xmin, xmax, dx, true, outNan, obj.gridVectors_{:});
                    end
                elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.SPLINE
                    Vtemp = coder.internal.interpolate.splineEvalNdScatter(nd, ...
                        obj.splineCoefsND, qp, ord, pcs, j, obj.gridVectors_{:});
                elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.NONE
                    Vtemp = outNan;
                end
            end
            
            % Insert at appropriate index.
            Vq = insertInterpolatedValues(Vtemp, j, k, Vq, nq);
        
        end
    end
end

%--------------------------------------------------------------------------

function qp = extractQueryPoint(Xq, nd, k)
    if iscell(Xq)
        qp = coder.nullcopy(zeros(1,nd,'like',Xq{1}));
        for i=1:nd
            qp(i) = Xq{i}(k);
        end
    else
        qp = coder.nullcopy(zeros(1,nd,'like',Xq));
        for i=1:nd
            qp(i) = Xq(k, i);
        end
    end
end

%--------------------------------------------------------------------------

function V = extractSampleValues(vals, j, nrows, V)
    coder.inline('always');    
    for k = 1:coder.internal.indexInt(numel(V))
        V(k) = vals(k + (j-1)*nrows);
    end
end

%--------------------------------------------------------------------------

function Vq = insertInterpolatedValues(Vtemp, j, qIdx, Vq, nq)
    coder.inline('always');
    insertIdx = coder.internal.indexInt(j-1)*coder.internal.indexInt(nq) + ...
        coder.internal.indexInt(qIdx);
    Vq(insertIdx) = Vtemp;
end

%--------------------------------------------------------------------------

function VV = expandVal(V, VV, ND, gridVec)
    for i = 1:numel(V)
        ind = cell(1,ND);
        [ind{:}] = ind2sub(size(V),i);
        for j = 1:ND
            ind{j} = ind{j} + 1;
        end
        VV(sub2ind(size(VV),ind{:})) = V(i);
    end

    nx = coder.nullcopy(zeros(1,ND,coder.internal.indexIntClass()));
    for i = 1:ND
        nx(i) = numel(gridVec{i});
    end

    for i = 1:ND
        nrows = coder.internal.prodsize(VV, 'below', i);
        ncols = coder.internal.prodsize(VV, 'above', i);
        for jj = 1:nrows
            for kk = 1:ncols
                sz = [nrows, size(VV,i), ncols];
                VV(sub2ind(sz,jj,1,kk)) = 3*VV(sub2ind(sz,jj,2,kk)) - 3*VV(sub2ind(sz,jj,3,kk)) + VV(sub2ind(sz,jj,4,kk));
                VV(sub2ind(sz,jj,nx(i)+2,kk)) = 3*VV(sub2ind(sz,jj,nx(i)+1,kk)) - 3*VV(sub2ind(sz,jj,nx(i),kk)) + VV(sub2ind(sz,jj,nx(i)-1,kk));
            end
        end
    end   
end

%--------------------------------------------------------------------------

function [xmin, xmax, dx] = getMinMaxOfGrid(nd, obj)
    % Assign minima, maxima and diff of elements in each dimension.
    % Used in linear, nearest and cubic.
    dx = coder.nullcopy(zeros(1, nd, 'like', real(obj.gridValues)));
    
    xmin = coder.nullcopy(zeros(1,nd,'like',obj.gridVectors_{1}));
    xmax = coder.nullcopy(zeros(1,nd,'like',obj.gridVectors_{1}));
    for i = 1:nd
        dx(i) = obj.gridVectors_{i}(2) - obj.gridVectors_{i}(1);
        xmin(i) = obj.gridVectors_{i}(1);
        xmax(i) = obj.gridVectors_{i}(end);
    end
end