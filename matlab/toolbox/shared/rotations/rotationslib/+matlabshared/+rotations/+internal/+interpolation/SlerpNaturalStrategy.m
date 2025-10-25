classdef (Hidden) SlerpNaturalStrategy < matlabshared.rotations.internal.interpolation.InterpolationStrategy 
%   This class is for internal use only. It may be removed in the future. 
%   %SLERPNATURALSTRATEGY The slerp-natural interpolation strategy concrete class


%   Copyright 2024 The MathWorks, Inc.		

    %#codegen

    methods
        function y = interpolate(~, xq, xhigh, xlow, yhigh, ylow, ~, ~)
            h = (xq - xlow)./(xhigh - xlow);
            y = matlabshared.rotations.internal.privslerp(ylow, yhigh, h, false);
        end
        function y = normalizeLut(~, y)
            y = normalize(y);
        end
    end

end
