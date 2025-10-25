classdef (Abstract) Array < matlab.mixin.Scalar
%

%   Copyright 2024 The MathWorks, Inc.

    methods(Hidden)
        function ind = end(~,~,~) %#ok
            id = "MATLAB:NET:UnsupportedEndIndexingArray";
            MException(id, message(id)).throwAsCaller();
        end
    end

    methods(Access = protected)
        function varargout = parenReference(obj, indexOp)
            if nargout > 1
                % Assigning to multiple outputs not supported.
                id = "MATLAB:MultipleResultsFromIndexing";
                MException(id, message(id)).throwAsCaller();
            end

            % Convert the MATLAB (1-based) indices to .NET (0-based)
            [indices, ranks] = validateIndices(obj, indexOp(1).Indices);

            % Throw if the wrong number of indices were provided.
            % Only support indexing into the outermost or innermost array, 
            % in the case of jagged arrays.
            numInd = numel(indices);
            if numInd ~= ranks(1) && numInd ~= ranks(end)
                id = "MATLAB:class:UndefinedMethod";
                MException(id, message(id, "()", class(obj))).throwAsCaller();
            end

            % Extract the top-level element
            elem = obj.Get(indices{1:ranks(1)});

            % If the array is jagged, and more indices are provided,
            % iteratively index into the nested arrays
            if numel(indices) > ranks(1)
                for i = 2:numel(ranks)
                    validateElement(elem);
                    elem = elem.Get(indices{ranks(i-1)+1:ranks(i)});
                end
            end

            if isscalar(indexOp)
                varargout{1} = elem;
                return;
            end
                
            % Additional operations
            validateElement(elem);
            indexOp = indexOp(2:end);

            try
                % Perform the other operations. If an error is thrown,
                % the error should appear as though it was thrown AFTER
                % the indexing operation.
                if nargout == 1
                    varargout{1} = elem.(indexOp);
                elseif nargout == 0
                    elem.(indexOp);
                    if exist("ans", "var")
                        % Assign ans if one was returned
                        varargout{1} = ans; %#ok
                    end
                end
            catch ME
                ME.throwAsCaller();
            end
        end

        function obj = parenAssign(obj, indexOp, varargin)

            % Convert the MATLAB (1-based) indices to .NET (0-based)
            [indices, ranks] = validateIndices(obj, indexOp(1).Indices);

            % Throw if the wrong number of indices were provided.
            % Only support indexing into the outermost or innermost array, 
            % in the case of jagged arrays.
            numInd = numel(indices);
            if numInd ~= ranks(1) && numInd ~= ranks(end)
                id = "MATLAB:class:UndefinedMethod";
                MException(id, message(id, "()", class(obj))).throwAsCaller();
            end

            % For algorithmic convenience, prepend with a 0.
            ranks = [0; ranks];

            % Use the top-level element to start.
            elem = obj;

            % If the array is jagged, and more indices are provided,
            % iteratively index into the nested arrays.
            i = 1;
            if numel(indices) > ranks(2)
                % Remember not to index into the last element - we must
                % call Set instead of Get for that.
                for i = 2:numel(ranks)-1
                    elem = elem.Get(indices{ranks(i-1)+1:ranks(i)});
                    validateElement(elem);
                end
            end

            % Assign a value
            if isscalar(indexOp)
                elem.Set(indices{ranks(i)+1:end}, varargin{1});
                return;
            end
                
            % Additional operations
            elem = elem.Get(indices{ranks(i)+1:end});

            try
                % Perform the other operations. If an error is thrown,
                % the error should appear as though it was thrown AFTER
                % the indexing operation.
                validateElement(elem);
                indexOp = indexOp(2:end);
                [elem.(indexOp)] = varargin{:};
            catch ME
                ME.throwAsCaller();
            end
        end
    
        function obj = parenDelete(obj, indexOp)
            % parenDelete is the equivalent of parenAssign with null
            try
                obj = parenAssign(obj, indexOp, []);
            catch ME
                ME.throwAsCaller()
            end
        end
    
        function n = parenListLength(~, ~, ~)
            % All .NET indexers will return exactly one output
            n = 1;
        end

    end

end

function validateElement(elem)
    % Throws if the element is null.
    if isempty(elem)
        id = "MATLAB:NET:NullObjectIndexing";
        MException(id, message(id)).throwAsCaller();
    end
end

function [indices, ranks] = validateIndices(obj, indices)
    % Convert the indices from 1-based to 0-based. Validates the number of
    % indices is supported for the given array, throws if validation fails.
    % INDICES 0-based indices
    % RANKS cumsum on the ranks of the array

    % Get the 0-based indices. Throws if any are invalid.
    try
        for i = 1:numel(indices)
            indices{i} = makeZeroBasedOrThrow(indices{i});
        end
    catch ME
        ME.throwAsCaller()
    end

    % Determine how many indices are required for this array.
    % Do this by extracting commas in the class name.
    dims = extractBetween(string(class(obj)), "[", "]");

    % Array dimensions in the classname are inner-to-outer from
    % left-to-right. Reverse the ranks to represent the number of indices
    % required to iteratively index into a jagged array.
    ranks = strlength(dims) + 1;
    ranks = flip(ranks);
    ranks = cumsum(ranks);
end

function n = makeZeroBasedOrThrow(n)
    if isscalar(n) && isnumeric(n) && isreal(n) && isfinite(n) && ~issparse(n) && n > 0 && floor(n) == n
        n = int32(n - 1);
    else
        MException( ...
            "MATLAB:NET:InvalidArrayIndex", ...
            message("MATLAB:NET:InvalidArrayIndex"))...
            .throwAsCaller();
    end
end
