classdef (Hidden) PreviousStrategy < matlabshared.rotations.internal.interpolation.InterpolationStrategy 
%   This class is for internal use only. It may be removed in the future. 
%   %PREVIOUSSTRATEGY The previous interpolation strategy concrete class

%   Copyright 2024 The MathWorks, Inc.		

    %#codegen

    methods
        function y = interpolate(~, xq, xhigh, ~, yhigh, ylow, ~, ~)
            idx = xq == xhigh;
            y = zeros(size(idx), "like", ylow);
            y(idx) = yhigh(idx);
            y(~idx) = ylow(~idx);
        end
    end

end
