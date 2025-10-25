classdef ArrowException < MException
%ARROWEXCEPTION Represents exceptions thrown when deconstructing MATLAB
% datatypes into structs that can be consued by the C++ layer for
% conversion to Arrow datatypes. Subclasses MException.
%
% This class has three properties: MessageHoleValues, Cause, and Reference.
%
% MessageHoleValues is a cell array containing the values to substitute in
% the holes of the error message associated with the identifier.
%
% Cause is a matlab.io.internal.arrow.error.ErrorLocation object. This
% object contains a vector of IndexOperations. This vector represents a
% sequence of indexing operations to apply to the original array to view
% the element in the array that caused the error.
%
% Reference is either a scalar <missing> value or a
% matlab.io.internal.arrow.error.ErrorLocation object. If Reference is not
% missing, this object refers to the element in the original array from
% which we inferred the expected structure of subsequent elements. Since
% not all matlab2arrow exceptions include a reference location, this
% property can be missing.

% Copyright 2022 The MathWorks, Inc.

    properties(SetAccess = private)
        %MESSAGEHOLEVALUES      A cell array containing the values to
        %                       substitute in the holes of the error
        %                       message associated with the identifier.
        MessageHoleValues(1, :) cell

        %CAUSE                  An error location object representing the
        %                       location within the original array that
        %                       caused the error/exception to be thrown.
        Cause(1, 1) matlab.io.internal.arrow.error.ErrorLocation

        %REFERENCE              Either a scalar <missing> vlaue or an
        %                       ErrorLocation object. If not missing,
        %                       Referece refers to the element in the
        %                       original array from which we inferred the
        %                       expected structure of subsequent elements.
        Reference(1, 1) = missing;
    end

    methods
        function obj = ArrowException(errId, nvargs)
            arguments
                errId(1, 1) string {mustBeNonmissing}
                nvargs.MessageHoleValues(1, :) cell = {}
                nvargs.HasReferenceLocation(1, 1) logical = false;
            end
            obj = obj@MException(errId, "", "");
            obj.MessageHoleValues = nvargs.MessageHoleValues;
            if nvargs.HasReferenceLocation
                obj.Reference = matlab.io.internal.arrow.error.ErrorLocation();
            end
        end

        function obj = appendBracesIndexOperation(obj, indexArgument)
            arguments
                obj
            end
            arguments (Repeating)
                indexArgument double
            end
            % indexArgument must be a cell array with either with one
            % or two elements. Because indexArgument is a positional input
            % argument, the number of repeated indexArgument parameters are
            % included in nargin. We can use this to validate the number of
            % inputs provided.
            narginchk(2, 3);
            obj.Cause = appendBracesIndexOperation(obj.Cause, indexArgument{1});
            if ~ismissing(obj.Reference)
                obj.Reference = appendBracesIndexOperation(obj.Reference, indexArgument{end});
            end
        end

        function obj = appendDotIndexOperation(obj, indexArgument)
            obj.Cause = appendDotIndexOperation(obj.Cause, indexArgument);
            if ~ismissing(obj.Reference)
                obj.Reference = appendDotIndexOperation(obj.Reference, indexArgument);
            end
        end

        function obj = updateLastBracesOperationArgument(obj, startOffsets)
            obj.Cause = updateLastBracesOperationArgument(obj.Cause, startOffsets);
            if ~ismissing(obj.Reference)
                obj.Reference = updateLastBracesOperationArgument(obj.Reference, startOffsets);
            end
        end

        function indexExpression = getIndexingExpression(obj, variableName)
            indexExpression = getIndexingExpression(obj.Cause, variableName);
            if ~ismissing(obj.Reference)
                indexExpression(end + 1) = getIndexingExpression(obj.Reference, variableName);
            end
        end
    end

    methods(Static)
        function makeAndThrow(errId, nvargs)
            arguments
                errId(1, 1) string {mustBeNonmissing}
                nvargs.MessageHoleValues(1, :) cell = {}
                nvargs.HasReferenceLocation(1, 1) logical = false;
            end
            import matlab.io.internal.arrow.error.ArrowException

            % Construct the ArrowException.
            nvargs = namedargs2cell(nvargs);
            except = ArrowException(errId, nvargs{:});

            % Throw the newly constructed ArrowException.
            throw(except);
        end
    end
end
