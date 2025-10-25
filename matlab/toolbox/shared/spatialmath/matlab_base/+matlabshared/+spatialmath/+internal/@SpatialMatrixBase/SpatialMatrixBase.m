classdef (Abstract, Hidden) SpatialMatrixBase < ...
        coder.mixin.internal.SpoofReport
%This class is for internal use only. It may be removed in the future.

%SpatialMatrixBase Base class for all se / so classes
%   It implements the storage and management of the underlying matrices
%   (either 2x2, 3x3, or 4x4).
%   All methods on this class need to support codegen.
%
%   Deriving from coder.mixin.internal.SpoofReport to ensure that size of
%   object array is displayed correctly in the codegen report.

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    properties (Access = {...
                           ?matlabshared.spatialmath.internal.SpatialMatrixBase, ...
                           ?matlab.unittest.TestCase})
        %MInd - Linear indices for matrices in M
        %   This contains the indices 1:prod(size(MInd)) and shaped in the
        %   format of the object array. For example, for an array of size
        %   2x3, size(MInd) will be [2 3] and contain the values
        %   [1 3 5;2 4 6]
        %
        %   Note that this property has to be listed as first property for
        %   the SpoofReport base class to correctly list the object array
        %   size in the codegen report.
        MInd

        %M - Matrix data storage container
        %   This is a 3-dimensional numeric array of rotation or transformation
        %   matrices. It has the shape AxAxB, where A = 3 or 4 and B is
        %   numel(MInd). Use the MInd property to find the index for B to
        %   find the right matrix for an object array position.
        M
    end


    properties (Abstract, Constant, Hidden)
        %Dim - Dimensionality of underlying SE / SO matrix
        %   For example, for se3 (4x4 matrix), this should be 4
        %   This constant is used to allow reuse of methods for se3, so3,
        %   se2, and so2.
        Dim
    end

    properties (Constant, Hidden)
        %ValidNormalizationMethods - Valid conversion type input strings
        ValidNormalizationMethods = {'quaternion', 'svd', 'cross'}
    end

    % Externally defined, public methods
    methods
        y = cat(varargin)
        y = double(obj)
        y = horzcat(varargin)
        tf = iscolumn(obj)
        tf = isempty(obj)
        tf = eq(obj1,obj2)
        eq = isequal(varargin)
        tf = isequaln(varargin)
        tf = isfinite(obj)
        tf = isinf(obj)
        tf = isnan(obj)
        tf = ismatrix(obj)
        tf = isrow(obj)
        tf = isscalar(obj)
        tf = isvector(obj)
        o = ldivide(obj1, obj2)
        l = length(obj)
        o = mldivide(obj1, obj2)
        o = mrdivide(obj1, obj2)
        o = mtimes(obj1,obj2)
        n = ndims(obj)
        tf = ne(obj1,obj2)
        n = numel(obj)
        o = rdivide(obj1, obj2)
        y = single(obj)
        varargout = size(obj, varargin)
        o = times(obj1,obj2)
        c = underlyingType(obj)
        validateattributes(obj, varargin)
        y = vertcat(varargin)
    end

    % Externally defined, hidden, public methods
    methods (Hidden)
        disp(obj, varargin)
        e = end(obj,k,n)
        x = castLike(obj, a)
        T = onesLike(obj, varargin)
    end

    % Abstract, public methods that need to be defined by subclasses
    methods (Abstract)
        obj = ctranspose(obj)
        d = dist(obj, obj2)
        Tint = interp(obj, obj2, pts)
        Tnorm = normalize(obj, varargin)
        obj = pagectranspose(obj)
        obj = pagetranspose(obj)
        obj = permute(obj, order)
        obj = reshape(obj, varargin)
        obj = transpose(obj)
    end

    % Abstract, protected methods that need to be defined by subclasses
    methods (Abstract, Access=protected)
        q = toQuaternion(obj, numQuats, idx)
        R = quatToRotm(obj, q)
    end

    % Abstract, static, public methods that need to be defined by subclasses
    methods (Abstract, Static)
        o = ones(varargin)
    end

    methods (Abstract, Static, Hidden)
        obj = fromMatrix(T,sz)
    end

    % Externally defined, protected methods
    methods (Access = protected)
        eq = binaryIsEqual(obj1,obj2)
        eq = binaryIsEqualn(obj1,obj2)
        Rn = normalizeRotm(obj, method)
        obj = parenAssignSim(obj, rhs, className, varargin)
    end

    % Externally defined, static, protected methods
    methods (Static, Access = protected)
        [M1,M2,interpVec] = parseInterpInput(varargin)
        method = parseNormalizeInput(varargin)
        obj = parseSpatialMatrixInput(varargin)
    end

    methods (Access = {?matlabshared.spatialmath.internal.SpatialMatrixBase, ?matlab.unittest.TestCase})
        function ind = newIndices(obj, sz)
        %refreshIndices Regenerate and reshape indices for property MInd

            ind = cast(reshape(1:size(obj.M,3), sz), "like", obj.M);
        end
    end

end
