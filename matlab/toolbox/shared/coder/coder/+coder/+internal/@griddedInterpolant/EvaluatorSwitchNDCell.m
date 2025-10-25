function Vq = EvaluatorSwitchNDCell(obj, XqCell)
% Gridded queries, used to query grids.
% If interpolation and extrapolation methods are different. The
% interpolation runs on the entire grid

    %#codegen

    m = obj.interpMethodID;
    mExtrap = obj.extrapMethodID;
    
    if m == coder.internal.interpolate.interpMethodsEnum.SPLINE

        Vq = coder.internal.interpolate.TensorSplineInterp(obj.gridVectors_{:}, ...
            obj.gridValues, XqCell{:});
        % Vq = coder.internal.interpolate.splineEvalNd(obj.gridVectors_, obj.gridValues, ...
        %         obj.splineCoefsND, XqCell);

    else
        assert(m == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
            m == coder.internal.interpolate.interpMethodsEnum.NEAREST || ...
            m == coder.internal.interpolate.interpMethodsEnum.CUBIC);
        
        Vq = coder.internal.interpolate.TensorGriddedInterp(m, obj.gridVectors_{:}, ...
            obj.gridValues, XqCell{:});
    end
    
    if m ~= mExtrap
        VqExtrap = coder.nullcopy(Vq);
        
        if mExtrap == coder.internal.interpolate.interpMethodsEnum.SPLINE

            VqExtrap = coder.internal.interpolate.TensorSplineInterp(obj.gridVectors_{:}, ...
                obj.gridValues, XqCell{:});
            % VqExtrap = coder.internal.interpolate.splineEvalNd(obj.gridVectors_, obj.gridValues, ...
            %     obj.splineCoefsND, XqCell);
    
        elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.LINEAR || ...
                mExtrap == coder.internal.interpolate.interpMethodsEnum.NEAREST || ...
                mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC
            
            VqExtrap = coder.internal.interpolate.TensorGriddedInterp(mExtrap, obj.gridVectors_{:}, ...
                obj.gridValues, XqCell{:});
        end

        isnone = coder.const(mExtrap == coder.internal.interpolate.interpMethodsEnum.NONE);
        Vq = coder.internal.interpolate.maskExtrap(VqExtrap, isnone, Vq, obj.gridVectors_{:}, XqCell{:});

    end
end

