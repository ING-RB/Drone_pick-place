function [METHOD, EXTRAPp] = validateMethodDependingOnGrid(gridVectors, defaultVectors, ...
                METHOD, EXTRAPp)
    % checks if the given method can be used on the input gridVectors.

    %   Copyright 2022-2023 The MathWorks, Inc.
    

    %#codegen
    
    if ( (METHOD == coder.internal.interpolate.interpMethodsEnum.CUBIC) || ...
            (EXTRAPp == coder.internal.interpolate.interpMethodsEnum.CUBIC) )
        % assigns alternate methods for cubic if, it is invalid for 
        % given vector inputs and issues a warning.

        cgc = coder.internal.griddedInterpolant.checkIfGridSupportsCubic(gridVectors, defaultVectors);
        if (cgc(1))
            if METHOD == coder.internal.interpolate.interpMethodsEnum.CUBIC
                METHOD = uint8(coder.internal.interpolate.interpMethodsEnum.LINEAR);
            end
            if (EXTRAPp == coder.internal.interpolate.interpMethodsEnum.CUBIC)
                EXTRAPp = uint8(coder.internal.interpolate.interpMethodsEnum.LINEAR);
            end
            coder.internal.warning('MATLAB:griddedInterpolant:CubicNeedsThreeWarnId');
        end
        if (cgc(2))
            if (METHOD == coder.internal.interpolate.interpMethodsEnum.CUBIC)
                METHOD = uint8(coder.internal.interpolate.interpMethodsEnum.SPLINE);
            end
            if (EXTRAPp == coder.internal.interpolate.interpMethodsEnum.CUBIC)
                EXTRAPp = uint8(coder.internal.interpolate.interpMethodsEnum.SPLINE);
            end
            coder.internal.warning('MATLAB:griddedInterpolant:CubicUniformOnlyWarnId');
        end

    end

    if (~isempty(gridVectors) && ~isscalar(gridVectors))
        % Error out if next, previous, pchip is provided as method for nD
        % inputs. 
        if (METHOD == coder.internal.interpolate.interpMethodsEnum.NEXT)
            coder.internal.error('Coder:toolbox:Next1Donly');
        elseif (METHOD == coder.internal.interpolate.interpMethodsEnum.PCHIP)
            coder.internal.error('Coder:toolbox:Pchip1Donly');
        elseif (METHOD == coder.internal.interpolate.interpMethodsEnum.PREVIOUS)
            coder.internal.error('Coder:toolbox:Previous1Donly');
        end

        if strcmp(EXTRAPp, "next")
            coder.internal.error('Coder:toolbox:Next1Donly');
        elseif strcmp(EXTRAPp, "pchip")
            coder.internal.error('Coder:toolbox:Pchip1Donly');
        elseif strcmp(EXTRAPp, "previous")
            coder.internal.error('Coder:toolbox:Previous1Donly');
        end

    end

end

% LocalWords:  Donly
