classdef (Hidden) InterpolationStrategy
%   This class is for internal use only. It may be removed in the future. 
%INTERPOLATIONSTRATEGY Base class for interpolation strategy pattern

%   Copyright 2024 The MathWorks, Inc.    

    %#codegen

   methods (Abstract)
       y = interpolate(obj, xq, xhigh, xlow, yhigh, ylow, xlowidx, page);
   end

   methods 
       % Suppressing unused variable MLINT below to illustrate API for subclasses
       function obj = plan(obj, addrs, values) %#ok<INUSD>
           % Default implementation is nothing
       end
       function y = normalizeLut(obj,y) %#ok<INUSD>
            % Default is not to normalize 
       end
   end
end
