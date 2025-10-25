classdef Arrow2MatlabOptions
    %ARROW2MATLABOPTIONS Defines parameters for converting Arrow data types
    % to MALTAB data types.
    
    %   Copyright 2021 The MathWorks, Inc.

    properties
        % PreserveVariableNames   A scalar logical that indicates if the
        %                         non-ASCII and spaces characters in the
        %                         original Arrow Table variable names 
        %                         should be preserved.
        PreserveVariableNames(1, 1) logical = false;


        % TableVariableName   A scalar string storing the name of the Arrow
        %                     Table variable being converted into a MATLAB
        %                     table variable.
        %
        % Used to determine which error to throw.
        TableVariableName(1, 1) string = string(missing);

        % ArrowTypeConversionOptions   Options for controlling conversion
        %                              from Arrow types to MATLAB types.
        %
        % Used to handle promotion to double for integer and logical types, as well
        % as NULL value handling.
        ArrowTypeConversionOptions(1, 1) matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions = ...
            matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions();
    end

    properties(Constant, Hidden)
        % save-load metadata
        ClassVersion(1, 1) double = 1;
        EarliestSupportedVersion(1, 1) double = 1;
    end

    properties(Dependent)
        % IsTableVariable   A scalar logical indicating if arrow2matlab is
        %                   constructing a MATLAB Table variable from an
        %                   Arrow Table variable.
        IsTableVariable(1, 1) logical
    end

    methods
        function obj = Arrow2MatlabOptions(opts)
            arguments
                opts.PreserveVariableNames(1, 1) logical = false
                opts.TableVariableName(1, 1) string = string(missing);
                opts.ArrowTypeConversionOptions(1, 1) matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions = ...
                    matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions();
            end

            obj.PreserveVariableNames = opts.PreserveVariableNames;
            obj.TableVariableName = opts.TableVariableName;
            obj.ArrowTypeConversionOptions = opts.ArrowTypeConversionOptions;
        end

        function tf = get.IsTableVariable(obj)
            tf = ~ismissing(obj.TableVariableName);
        end
    end

    methods(Hidden)
        function s = saveobj(obj)
            s.ClassVersion = obj.ClassVersion;
            s.EarliestSupportedVersion = obj.EarliestSupportedVersion;
            s.PreserveVariableNames = obj.PreserveVariableNames;
            s.TableVariableName = obj.TableVariableName;
            s.ArrowTypeConversionOptions = obj.ArrowTypeConversionOptions;
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            import matlab.io.arrow.internal.Arrow2MatlabOptions

            % Error if we are sure that a version incompatibility is about to occur.
            if s.EarliestSupportedVersion > Arrow2MatlabOptions.ClassVersion
                error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
            end

            obj = Arrow2MatlabOptions;
            obj.PreserveVariableNames = s.PreserveVariableNames;
            obj.TableVariableName = s.TableVariableName;
            obj.ArrowTypeConversionOptions = s.ArrowTypeConversionOptions;
        end
    end
end

