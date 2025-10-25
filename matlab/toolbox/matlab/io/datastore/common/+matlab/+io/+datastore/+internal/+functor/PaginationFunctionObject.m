classdef PaginationFunctionObject < matlab.mixin.internal.FunctionObject ...
                                  & matlab.mixin.Copyable
%PaginationFunctionObject   Returns a paginating ArrayDatastore of the
%   specified ReadSize.

%   Copyright 2022 The MathWorks, Inc.

    properties
        ReadSize (1, 1) double {mustBeInteger, mustBePositive} = 1;
    end

    methods
        function func = PaginationFunctionObject(ReadSize)
            func.ReadSize = ReadSize;
        end

        function ds = parenReference(func, T, info)
            % We don't want to return ArrayDatastore's info struct. So use
            % a transform to return identical data, but modify the info
            % struct.
            % Since TransformedDatastore returns [] when empty, we need to
            % override the Schema again.
            ds = arrayDatastore(T, ReadSize=func.ReadSize, OutputType="same") ...
                .transform(@(data, ~) deal(data, info), IncludeInfo=true) ...
                .overrideSchema(T([], :));
        end
    end

    % Save-load logic.
    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ParquetDatastore2 in R2022b.
        ClassVersion (1, 1) double = 1;
    end

    methods
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % State properties
            S.ReadSize = obj.ReadSize;
        end
    end

    methods (Static)
        function obj = loadobj(S)

            import matlab.io.datastore.internal.functor.PaginationFunctionObject

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > PaginationFunctionObject.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            obj = PaginationFunctionObject(S.ReadSize);
        end
    end
end
