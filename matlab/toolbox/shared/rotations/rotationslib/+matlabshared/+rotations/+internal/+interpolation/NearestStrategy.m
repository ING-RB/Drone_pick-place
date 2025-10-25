classdef (Hidden) NearestStrategy < matlabshared.rotations.internal.interpolation.InterpolationStrategy 
%   This class is for internal use only. It may be removed in the future. 
%   %NEARESTSTRATEGY The nearest interpolation strategy concrete class

%   Copyright 2024 The MathWorks, Inc.		

    %#codegen

    methods
        function y = interpolate(~, xq, xhigh, xlow, yhigh, ylow, ~, ~)
            highdiff = xhigh - xq;
            lowdiff = xq - xlow;

            idx = lowdiff < highdiff;
            y = zeros(size(idx), "like", ylow);
            y(idx) = ylow(idx);
            y(~idx) = yhigh(~idx);
        end
    end

end
