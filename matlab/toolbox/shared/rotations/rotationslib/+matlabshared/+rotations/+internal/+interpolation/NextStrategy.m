classdef (Hidden) NextStrategy < matlabshared.rotations.internal.interpolation.InterpolationStrategy 
%   This class is for internal use only. It may be removed in the future. 
%   %NEXTSTRATEGY The next interpolation strategy concrete class

%   Copyright 2024 The MathWorks, Inc.		

    %#codegen

    methods
        function y = interpolate(~, xq, ~, xlow, yhigh, ylow, ~, ~)
            idx = xq == xlow;
            y = zeros(size(idx), "like", ylow);
            y(idx) = ylow(idx);
            y(~idx) = yhigh(~idx);
        end
    end

end
