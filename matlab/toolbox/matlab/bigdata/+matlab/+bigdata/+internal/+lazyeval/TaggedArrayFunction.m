%TaggedArrayFunction
% Function handle wrapper that manages all TaggedArray inputs.
%
% This will unwrap tagged array types prior to calling the function handle
% and if necessary, wrap the output. TaggedArray types include:
%  * BroadcastArray: Complete arrays that have been explicitly broadcasted
%  to all partitions and all chunks
%  * UnknownEmptyArray: Chunks of height 0 where either the type or small
%  size is not known.

% Copyright 2016-2019 The MathWorks, Inc.

classdef (Sealed) TaggedArrayFunction < matlab.mixin.Copyable
    properties (SetAccess = immutable)
        % The underlying function handle to be invoked. This is public so
        % that debug and log utilities can unwrap this TaggedArrayFunction.
        Handle;
    end
    
    methods (Static)
        function fh = wrap(fh, options)
            % Wrap a FunctionHandle object in a FunctionHandle that will
            % handle tagged input types. This will handle both broadcasts
            % and unknown empty inputs, converting each to their respective
            % non-tagged representations for the function handle.
            import matlab.bigdata.internal.FunctionHandle;
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            if nargin < 2 || isempty(options) || ~options.PassTaggedInputs
                fh = fh.copyWithNewHandle(TaggedArrayFunction(fh.Handle));
            end
        end
    end
    
    methods
        function varargout = feval(obj, varargin)
            import matlab.bigdata.internal.UnknownEmptyArray;
            
            isAnyUnknown = false;
            for ii = 1:numel(varargin)
                if isa(varargin{ii}, 'matlab.bigdata.internal.TaggedArray')
                    if UnknownEmptyArray.isUnknown(varargin{ii})
                        % Track if the TaggedArray is an UnknownEmptyArray,
                        % do not take its underlying value.
                        isAnyUnknown = true;
                    else
                        % Only get the underlying value of other types of
                        % TaggedArray.
                        varargin{ii} = getUnderlying(varargin{ii});
                    end
                end
            end
            
            if isAnyUnknown
                % If any of the inputs is unknown, propagate
                % UnknownEmptyArray.
                varargout = cell(1, nargout);
                for ii = 1 : numel(varargout)
                    varargout{ii} = UnknownEmptyArray.build();
                end
            else
                [varargout{1:nargout}] = feval(obj.Handle, varargin{:});
            end
        end
    end
    
    methods (Access = private)
        function obj = TaggedArrayFunction(handle)
            % Private constructor for the static wrap function.
            obj.Handle = handle;
        end
    end
    
    methods (Access = protected)
        function obj = copyElement(obj)
            % Override of copy to ensure underlying array is copied.
            import matlab.bigdata.internal.lazyeval.TaggedArrayFunction;
            if isa(obj.Handle, 'matlab.mixin.Copyable')
                obj = TaggedArrayFunction(copy(obj.Handle));
            else
                obj = TaggedArrayFunction(obj.Handle);
            end
        end
    end
end
