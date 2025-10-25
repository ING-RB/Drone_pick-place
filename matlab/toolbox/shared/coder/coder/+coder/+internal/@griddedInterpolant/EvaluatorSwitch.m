function Vq = EvaluatorSwitch(obj, Xq, Vq)
    % dispatch function to call relevant interpolation function
    % function supports only 1-D queries.
    % interpolation functions are shared with interp1.

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen
    
    coder.internal.prefer_const(obj);
    m = obj.interpMethodID;
    mExtrap = obj.extrapMethodID;
    ONE = coder.internal.indexInt(1);
    
    if isvector(obj.gridValues)
        nyrows = coder.internal.indexInt(numel(obj.gridValues));
        nycols = ONE;
    else
        nyrows = coder.internal.indexInt(size(obj.gridValues,1));
        nycols = coder.internal.prodsize(obj.gridValues, 'above', 1);
    end

    nx = coder.internal.indexInt(numel(obj.gridVectors_{1}));
    minx = obj.gridVectors_{1}(1);
    secx = obj.gridVectors_{1}(2);
    penx = obj.gridVectors_{1}(end - 1);
    maxx = obj.gridVectors_{1}(end);

    nxi = coder.internal.indexInt(numel(Xq));

    if m==mExtrap
        % INTERP == EXTRAP
        if m == coder.internal.interpolate.interpMethodsEnum.LINEAR
            for k = 1:nxi
                Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k,true, ...
                    nx,minx,penx,maxx,obj.gridVectors_{1}); 
            end
        elseif m == coder.internal.interpolate.interpMethodsEnum.CUBIC                       
            h = obj.gridVectors_{1}(2) - obj.gridVectors_{1}(1);
            if obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC
                for k = 1:nxi                        
                    Vq = coder.internal.interpolate.interp1cubicConvLoopBody( ...
                        obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k, ...
                        true,minx,secx,penx,maxx,nx,obj.gridVectors_{1},h);                
                    
                end
            elseif obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.LINEAR
                for k = 1:nxi
                    Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k,true, ...
                        nx,minx,penx,maxx,obj.gridVectors_{1}); 
                end
            else
                for k = 1:nxi
                    Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                        obj.ppStruct1DInterp, nycols, Xq, Vq, nxi, k, true, obj.gridVectors_{1});
                end
            end

        elseif m == coder.internal.interpolate.interpMethodsEnum.SPLINE || ... 
                m == coder.internal.interpolate.interpMethodsEnum.PCHIP || ... 
                m == coder.internal.interpolate.interpMethodsEnum.MAKIMA
            
            for k = 1:nxi
                Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                    obj.ppStruct1DInterp, nycols, Xq, Vq, nxi, k, true, obj.gridVectors_{1});
            end
        elseif m == coder.internal.interpolate.interpMethodsEnum.MAKIMA
            coder.internal.error('MATLAB:griddedInterpolant:BadInterpTypeErrId')
        else
            for k = 1:nxi
                Vq = coder.internal.interpolate.interp1StepLoopBody( ...
                    obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k, m,true,minx, ...
                    maxx,obj.gridVectors_{1});                
            end
        end
    else
        % INTERP ~= EXTRAP
        if mExtrap == coder.internal.interpolate.interpMethodsEnum.LINEAR
            for k = 1:nxi
                if Xq(k) < minx || Xq(k) > maxx
                    Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues,nyrows,nycols,Xq, ...
                        Vq,nxi,k,true,nx,minx,penx,maxx,obj.gridVectors_{1});            
                end
            end
        elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.CUBIC            
            h = obj.gridVectors_{1}(2) - obj.gridVectors_{1}(1);
            for k = 1:nxi
                if Xq(k) < minx || Xq(k) > maxx
                    
                    if obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC
                
                        Vq = coder.internal.interpolate.interp1cubicConvLoopBody( ...
                            obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k, ...
                            true,minx,secx,penx,maxx,nx,obj.gridVectors_{1},h);
                
                    elseif obj.extrapToUseForCubic == coder.internal.interpolate.interpMethodsEnum.LINEAR
                        Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues, ...
                            nyrows,nycols,Xq,Vq,nxi,k,true, ...
                            nx,minx,penx,maxx,obj.gridVectors_{1});
                    else
                        Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                            obj.ppStruct1DExtrap, nycols, Xq, Vq, nxi, k, true, obj.gridVectors_{1});
                    end
                end
            end
        elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.SPLINE || ... 
                mExtrap == coder.internal.interpolate.interpMethodsEnum.PCHIP || ... 
                mExtrap == coder.internal.interpolate.interpMethodsEnum.MAKIMA
            
            for k = 1:nxi
                if Xq(k) < minx || Xq(k) > maxx
                    Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                        obj.ppStruct1DExtrap, nycols, Xq, Vq, nxi, k, true, obj.gridVectors_{1});
                end
            end
        elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.MAKIMA
            coder.internal.error('MATLAB:griddedInterpolant:BadInterpTypeErrId');
        elseif mExtrap == coder.internal.interpolate.interpMethodsEnum.NONE
            NAN = coder.const(coder.internal.interpolate.interpNaN(Vq));
            for k = 1:nxi
                if Xq(k) < minx || Xq(k) > maxx
                    for j = 0:nycols-1
                        Vq(k + j*nxi) = NAN;
                    end
                end
            end
        else
            for k = 1:nxi
                if Xq(k) < minx || Xq(k) > maxx
                    Vq = coder.internal.interpolate.interp1StepLoopBody( ...
                        obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k,mExtrap,true,minx, ...
                        maxx,obj.gridVectors_{1});
                end
            end
        end

        if m == coder.internal.interpolate.interpMethodsEnum.LINEAR
            for k = 1:nxi
                if ~(Xq(k) < minx || Xq(k) > maxx)
                    Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues,nyrows,nycols,Xq, ...
                        Vq,nxi,k,false,nx,minx,penx,maxx,obj.gridVectors_{1});
                end
            end
        elseif m == coder.internal.interpolate.interpMethodsEnum.CUBIC            
            h = obj.gridVectors_{1}(2) - obj.gridVectors_{1}(1);
            for k = 1:nxi
                if ~(Xq(k) < minx || Xq(k) > maxx)
                    if obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.CUBIC
                
                        Vq = coder.internal.interpolate.interp1cubicConvLoopBody( ...
                            obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k, ...
                            true,minx,secx,penx,maxx,nx,obj.gridVectors_{1},h);
                    elseif obj.interpToUseForCubic == coder.internal.interpolate.interpMethodsEnum.LINEAR
                        Vq = coder.internal.interpolate.interp1LinearLoopBody(obj.gridValues, ...
                            nyrows,nycols,Xq,Vq,nxi,k,true, ...
                            nx,minx,penx,maxx,obj.gridVectors_{1});
                    else
                        Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                            obj.ppStruct1DInterp, nycols, Xq, Vq, nxi, k, true, obj.gridVectors_{1});
                    end
                end
            end
        elseif m == coder.internal.interpolate.interpMethodsEnum.SPLINE || ... 
                m == coder.internal.interpolate.interpMethodsEnum.PCHIP || ... 
                m == coder.internal.interpolate.interpMethodsEnum.MAKIMA
            
            for k = 1:nxi
                if ~(Xq(k) < minx || Xq(k) > maxx)
                    Vq = coder.internal.interpolate.interp1SplineMakimaOrPCHIPbody( ...
                        obj.ppStruct1DInterp,nycols,Xq,Vq,nxi,k,false,obj.gridVectors_{1});
                end
            end
        else
            for k = 1:nxi
                if ~(Xq(k) < minx || Xq(k) > maxx)
                    Vq = coder.internal.interpolate.interp1StepLoopBody( ...
                        obj.gridValues,nyrows,nycols,Xq,Vq,nxi,k, m,false,minx, ...
                        maxx,obj.gridVectors_{1});
                end
            end
        end
    end

end
