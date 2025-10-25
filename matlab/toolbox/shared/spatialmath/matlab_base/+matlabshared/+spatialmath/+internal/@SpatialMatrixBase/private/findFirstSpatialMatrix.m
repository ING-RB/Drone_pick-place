function [obj,idx] = findFirstSpatialMatrix(varargin)
%This function is for internal use only. It may be removed in the future.

%findFirstSpatialMatrix find the first spatial matrix object in passed arguments

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Local function called from several methods
    for i = 1:nargin
        if isa(varargin{i}, "matlabshared.spatialmath.internal.SpatialMatrixBase")
            obj = varargin{i};
            idx = i;
            return
        end
    end

end
