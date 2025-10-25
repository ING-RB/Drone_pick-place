%UnknownEmptyArray
% An empty array where either the small size or the type is not known.
%
% This exists to give specific chunks of output the permission to change
% size and/or type during a vertical concatenation with other chunks of the
% same array. Tall array algorithms are allowed to return this instead of
% an empty chunk if the size and/or type cannot be known.
%
% Note, this will never be passed as input to any operation. It will either
% merge with other chunks of the same array, or it will be propagated
% forward.

% Copyright 2017-2024 The MathWorks, Inc.

classdef (Sealed,  InferiorClasses = { ...
        ?table, ...
        ?timetable, ...
        ?categorical, ...
        ?string, ...
        ?datetime, ...
        ?duration, ...
        ?calendarDuration, ...
        ?matlab.internal.math.TDigest }) ...
        UnknownEmptyArray < matlab.bigdata.internal.TaggedArray
    
    methods (Static)
        function obj = build()
            % Build a UnknownEmptyArray.
            obj = matlab.bigdata.internal.UnknownEmptyArray();
        end
        
        function tf = isUnknown(obj)
            tf = isa(obj, 'matlab.bigdata.internal.UnknownEmptyArray');
        end
    end
    
    methods
        function sz = size(~, varargin)
            % Override of size. This is required by size asserting
            % operations.
            sz = size([], varargin{:});
        end
        
        function out = vertcat(varargin)
            % Override of vertcat. This will merge unknown empty arrays
            % where possible.
            import matlab.bigdata.internal.UnknownEmptyArray;
            
            isUnknown = cellfun(@UnknownEmptyArray.isUnknown, varargin);
            if all(isUnknown)
                out = UnknownEmptyArray.build();
            else
                out = matlab.bigdata.internal.util.vertcatCellContents(varargin(~isUnknown));
            end
        end

        function out = cat(dim, varargin)
            % Override of cat. This will merge unknown empty arrays where
            % possible.
            assert(dim == 1, "UnknownEmptyArray only supports cat in dim 1");
            out = vertcat(varargin{:});
        end
        
        function obj = subsref(obj, S)
            % Override of subsref. This is required for re-chunking and
            % buffering operations.
            assert(isscalar(S), ...
                'Assertion failed: Attempted to use unsupported multi-level indexing on an UnknownEmptyArray.');
            assert(S(1).type == "()", ...
                'Assertion failed: Attempted to use unsupported %s indexing on an UnknownEmptyArray.', ...
                S(1).type);
        end
    end
    
    % Overrides of TaggedArray interface.
    methods
        function obj = getUnderlying(obj)
            % Get the array underlying this UnknownEmptyArray.
            assert(false, 'Error. UnknownEmptyArray does not have an underlying value.')
        end
    end
    
    methods (Access = private)
        function obj = UnknownEmptyArray()
            % Private constructor for the static build function.
        end
    end
end
