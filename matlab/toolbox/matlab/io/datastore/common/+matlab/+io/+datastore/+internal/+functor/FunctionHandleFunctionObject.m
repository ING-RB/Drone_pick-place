classdef FunctionHandleFunctionObject < matlab.mixin.internal.FunctionObject ...
                                      & matlab.mixin.Copyable ...
                                      & matlab.mixin.CustomCompactDisplayProvider
%FunctionHandleFunctionObject   Wrap a function_handle in a FunctionObject.
%
%    Usage:
%       >> func = @(x) 2*x
%       >> func2 = FunctionHandleFunctionObject(func);
%       >> func2(3) % Returns 6.
%
%   Note that the usual caveats of working with function_handle
%   applies to this FunctionObject too:
%    - isequaln will always return true for lambda functions
%      So avoid doing testCase.verifyEqual for FunctionHandleFunctionObject in tests.
%    - Handle objects captured in the lambda's workspace will not
%      be deep-copied during copy().
%
%   See also: matlab.io.datastore.internal.functor.isConvertibleToFunctionObject,
%             matlab.mixin.internal.FunctionObject

%   Copyright 2022 The MathWorks, Inc.

    properties
        FunctionHandle
    end

    methods
        function func = FunctionHandleFunctionObject(FunctionHandle)
            arguments
                FunctionHandle (1, 1) function_handle
            end
            func.FunctionHandle = FunctionHandle;
        end

        function varargout = parenReference(func, varargin)
            [varargout{1:nargout}] = func.FunctionHandle(varargin{:});
        end

        % isequaln has some tricky behavior for anonymous function_handle. Basically,
        % it only returns true if two variables are pointing to the same function_handle.
        % Even if two function_handles are identical pure anonymous functions, they will not compare
        % isequaln true. To make things more interesting, this only applies to anonymous
        % function_handle but not to named function handles (like @readtable)
        %
        % As a result of this, any datastore that stores a function_handle property has to always
        % override isequaln and make it ignore the function_handle to avoid test failures. Datastores that do
        % this are: TransformedDatastore and FileDatastore. Some internal datastores need
        % to do this too: RepeatedDatastore, NestedDatastore, FileDatastore2.
        %
        % Overriding isequaln here means that FunctionHandleFunctionObject gets more complicated,
        % but in theory any future datastore that stores this as a property doesn't
        % have to rediscover and re-solve this tedious problem again.
        function tf = isequaln(func1, func2, varargin)

            isCorrectClass = @(x) isa(x, "matlab.io.datastore.internal.functor.FunctionHandleFunctionObject");

            % Return early if different classes were provided as input.
            if ~isCorrectClass(func1) || ~isCorrectClass(func2)
                tf = false;
                return;
            end

            % Now that the classes are validated to be the same, check the contents of
            % each function handle to compare them.
            funcMeta1 = functions(func1.FunctionHandle);
            funcMeta2 = functions(func2.FunctionHandle);

            if funcMeta1.type == "anonymous" && funcMeta2.type == "anonymous"
                tf = true; % Avoid comparing if both handles are anonymous.
            else
                tf = isequaln(func1.FunctionHandle, func2.FunctionHandle);
            end

            % Recursively handle the rest of the inputs.
            if numel(varargin) > 0
                tf = tf && isequaln(func2, varargin{:});
            end
        end
    end

    % Save-load metadata.
    properties (Access = private, Constant)
        % ClassVersion = 1 corresponds to the first release of FunctionHandleFunctionObject in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods
        function S = saveobj(func)
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = func.ClassVersion;

            % Public properties
            S.FunctionHandle = func.FunctionHandle;
        end
    end

    methods (Static)
        function func = loadobj(S)
            import matlab.io.datastore.internal.functor.FunctionHandleFunctionObject

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > FunctionHandleFunctionObject.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            func = FunctionHandleFunctionObject(S.FunctionHandle);
        end
    end

    % Display override: Make this look like a "normal" function_handle.
    methods
        function s = string(func)
            s = convertCharsToStrings(func2str(func.FunctionHandle));
        end

        function rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
            % Fit as many array elements in the available space as possible
            rep = obj.widthConstrainedDataRepresentation(displayConfiguration, width, ...
                AllowTruncatedDisplayForScalar=true, ...
                MinimumElementsToDisplay=1);
        end
    end
end
