classdef SO2cg < matlabshared.spatialmath.internal.SO2Base & ...
        coder.mixin.internal.indexing.ParenAssign
%This class is for internal use only. It may be removed in the future.

%SO2CG - Redirection class for so2 MATLAB Coder support.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    methods
        function obj = SO2cg(varargin)
            obj@matlabshared.spatialmath.internal.SO2Base(varargin{:});
        end
    end

    % Externally defined, public methods
    methods
        outObj = ctranspose(obj)
        outObj = pagectranspose(obj)
        outObj = pagetranspose(obj)
        outObj = permute(obj, order)
        outObj = reshape(obj, varargin)
        outObj = transpose(obj)
    end

    methods (Static)
        o = ones(varargin)
    end

    methods (Hidden)
        outObj = parenReference(obj, varargin)
        outObj = parenAssign(obj, rhs, varargin)
    end

    methods (Static)
        out = matlabCodegenToRedirected(in)
        out = matlabCodegenFromRedirected(obj)
    end

    methods (Static, Hidden)
        obj = fromMatrix(T,sz)
        name = matlabCodegenUserReadableName
    end

end
