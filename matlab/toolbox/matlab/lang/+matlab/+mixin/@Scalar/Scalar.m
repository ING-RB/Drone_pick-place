classdef (Abstract, HandleCompatible) Scalar < ...
        matlab.mixin.indexing.RedefinesParen
%matlab.mixin.Scalar  Superclass providing support for scalar classes
%
%   The matlab.mixin.Scalar class is an abstract class that prohibits
%   array-forming operations. Subclasses of matlab.mixin.Scalar have
%   the following characteristics:
%     - the size is always 1x1;
%     - concatenation is prohibited;
%     - forming an empty array is not possible.
%
%   By default, indexed reference and assignment with parentheses is
%   not supported, and these operations will error. However, a class
%   derived from matlab.mixin.Scalar can implement custom indexing
%   behavior using mixins.
%
%   matlab.mixin.Scalar methods:
%   Methods with a default implementation that can be overridden:
%       END             - Compute size in a given dimension of a scalar
%                         object; returns 1
%       parenReference  - Parentheses indexed reference; issues an
%                         error
%       parenAssign     - Parentheses indexed assignment; issues an
%                         error
%       parenDelete     - Parentheses indexed deletion; issues an error
%       parenListLength - Length of comma-separated list for
%                         parentheses indexing; issues an error
%   Sealed methods:
%       CAT             - Issues an error on an attempt to perform
%                         concatenation
%       CTRANSPOSE      - Conjugate transpose; returns the scalar
%                         object unchanged
%       EMPTY           - Issues an error on an attempt to create an
%                         empty array
%       HORZCAT         - Issues an error on an attempt to perform
%                         horizontal concatenation
%       ISEMPTY         - Always returns false for scalar objects
%       ISSCALAR        - Always returns true for scalar objects
%       LENGTH          - Length of the scalar object; always returns 1
%       NDIMS           - Number of dimensions of the scalar object;
%                         always returns 2
%       NUMEL           - Number of elements of the scalar object;
%                         always returns 1
%       RESHAPE         - Returns the scalar object unchanged
%       SIZE            - Returns the size of the scalar object, which
%                         is always 1x1
%       TRANSPOSE       - Transpose; returns the scalar object
%                         unchanged
%       VERTCAT         - Issues an error on an attempt to perform
%                         vertical concatenation
%
%   See also matlab.mixin.indexing
%

%   Copyright 2020-2023 The MathWorks, Inc.

    methods (Static, Hidden, Sealed, Access = public)
        function A = empty(varargin) %#ok<STOUT>
        %EMPTY  Issues an error on an attempt to create an empty array
            throwAsCaller(MException(message("MATLAB:class:emptyScalar")));
        end
    end

    methods (Access = public)
        function ind = end(~,~,~)
        %END  Compute size in a given dimension of a scalar object; returns 1
            ind = 1;
        end
    end

    methods (Access = protected)
        function varargout = parenReference(obj, ~) %#ok<STOUT>
        %parenReference  Parentheses indexed reference; issues an error
        %
        %   The parenReference method is called for indexed reference
        %   with parentheses. The base class implementation of this
        %   method always issues an error; this behavior can be
        %   overridden by subclasses.
        %
        %   See also
        %   matlab.mixin.indexing.RedefinesParen/parenReference
            throwAsCaller(MException(message("MATLAB:class:parenReferenceScalar", class(obj))));
        end

        function obj = parenAssign(obj, ~, varargin)
        %parenAssign  Parentheses indexed assignment; issues an error
        %
        %   The parenAssign method is called for indexed assignment
        %   with parentheses. The base class implementation of this
        %   method always issues an error; this behavior can be
        %   overridden by subclasses.
        %
        %   See also
        %   matlab.mixin.indexing.RedefinesParen/parenAssign
            if isequal(obj, [])
                className = class(varargin{1});
            else
                className = class(obj);
            end
            throwAsCaller(MException(message("MATLAB:class:parenAssignScalar", className)));
        end

        function obj = parenDelete(obj, ~)
        %parenDelete  Parentheses indexed deletion; issues an error
        %
        %   The parenDelete method is called for indexed deletion. The
        %   base class implementation of this method always issues an
        %   error; this behavior can be overridden by subclasses.
        %
        %   See also
        %   matlab.mixin.indexing.RedefinesParen/parenDelete
            throwAsCaller(MException(message("MATLAB:class:parenDeleteScalar", class(obj))));
        end

        function n = parenListLength(obj, ~, indexingContext) %#ok<STOUT>
        %parenListLength  Length of comma-separated list for parentheses
        %                 indexing; issues an error
        %
        %   The base class implementation of this method always issues
        %   an error; this behavior can be overridden by subclasses.
        %
        %   See also
        %   matlab.mixin.indexing.RedefinesParen/parenListLength
            className = class(obj);
            if indexingContext == matlab.indexing.IndexingContext.Assignment
                error(message("MATLAB:class:parenAssignScalar", className));
            else
                error(message("MATLAB:class:parenReferenceScalar", className));
            end
        end
    end

    methods (Sealed, Access = public)
        function TF = isempty(~)
        %ISEMPTY  Always returns false for scalar objects
            TF = false;
        end

        function TF = isscalar(~)
        %ISSCALAR  Always returns true for scalar objects
            TF = true;
        end

        function L = length(~)
        %LENGTH  Length of the scalar object; always returns 1
            L = 1;
        end

        function N = ndims(~)
        %NDIMS  Number of dimensions of the scalar object; always returns 2
            N = 2;
        end

        function n = numel(~)
        %NUMEL  Number of elements of the scalar object; always returns 1
            n = 1;
        end

        function varargout = size(~, varargin)
        %SIZE  Returns the size of the scalar object, which is always 1x1

        % Use the built-in function to perform error checking on the
        % input arguments and get the correct behavior with respect to
        % nargin/nargout.
            try
                [varargout{1:nargout}] = builtin("size", 0, varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end
    end

    methods (Hidden, Sealed, Access = public)
        function C = cat(varargin) %#ok<STOUT>
        %CAT  Issues an error on an attempt to perform concatenation
            scalarObjects = cellfun(@(v)isa(v, "matlab.mixin.Scalar"), varargin);
            firstScalarObject = varargin{find(scalarObjects, 1)};
            throwAsCaller(MException(message("MATLAB:class:concatenationScalar", class(firstScalarObject))));
        end

        function obj = ctranspose(obj)
        %CTRANSPOSE  Conjugate transpose; returns the scalar object
        %            unchanged
        end

        function C = horzcat(obj, varargin) %#ok<STOUT>
        %HORZCAT  Issues an error on an attempt to perform horizontal
        %         concatenation
            try
                cat(2, obj, varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end

        function obj = reshape(obj, varargin)
        %RESHAPE  Returns the scalar object unchanged
        %
        %   Returns the input unchanged if the requested size is 1x1;
        %   otherwise issues an error

        % Use the built-in function to perform error checking on the
        % inputs.
            try
                builtin("reshape", 0, varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end

        function obj = transpose(obj)
        %TRANSPOSE  Transpose; returns the scalar object unchanged
        end

        function C = vertcat(obj, varargin) %#ok<STOUT>
        %VERTCAT  Issues an error on an attempt to perform vertical
        %         concatenation
            try
                cat(1, obj, varargin{:});
            catch ME
                throwAsCaller(ME);
            end
        end
    end
end
