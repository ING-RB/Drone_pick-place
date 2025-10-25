classdef ParquetInfo
%PARQUETINFO Parquet file information

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        Filename string
        FileSize double
        NumRowGroups double
        RowGroupHeights (1,:) double
        VariableNames (1,:) string
        VariableTypes (1,:) string
        VariableCompression (1,:) string
        VariableEncoding (1,:) string
        Version string
    end

    properties (Access = private, Constant)
        % Save-load metadata:
        %   ClassVersion will be missing in ParquetInfo loaded from R2021b and older.
        %   ClassVersion = 2 corresponds to the R2022a release of ParquetInfo.
        ClassVersion(1, 1) double = 2;
    end

    methods
        function obj = ParquetInfo(filename)
            import matlab.io.parquet.internal.validateParquetReadFilename
            import matlab.io.parquet.internal.makeParquetException

            if nargin == 0
                % Default construction case, used during loadobj.
                return;
            end

            try
                [filename, fileObj] = validateParquetReadFilename(filename); %#ok<ASGLU>
                r = matlab.io.parquet.internal.ParquetInfo(filename);
            catch e
                e = makeParquetException(e, filename, "read");
                throwAsCaller(e);
            end

            % Project matching properties from internal info onto this obj
            obj = setProperties(obj, r);

            obj = normalize(obj);
        end
    end

    methods (Access = private)
        function obj = normalize(obj)
        % normalizing ParquetInfo involves:
        %
        % * Make per-variable property sizes consistent with the number
        %   of variables (as derived from VariableNames).
        % * Use <missing> to fill for any unknown or empty properties
        %   that might be due to unsupported or corrupt data.
        % * Converting statistics properties to a NumRowGroupsxNumVariables table.
        %
            numVars = numel(obj.VariableNames);
            varProps = ["VariableTypes", "VariableCompression", "VariableEncoding"];

            for ii = 1:numel(varProps)
                if isempty(obj.(varProps(ii)))
                    % Must be 1 x number of variables
                    obj.(varProps(ii)) = strings(1, numVars);
                end
                prop = obj.(varProps(ii));

                % Convert all "" to <missing> string value.
                missingValues = strlength(prop) == 0;
                obj.(varProps(ii))(missingValues) = string(missing);
            end

            missingStrs = ["", "UNKNOWN"];
            if isempty(obj.Version)
                obj.Version = missing;
            else
                % Version property might be "unknown"
                obj.Version = standardizeMissing(obj.Version, missingStrs);
            end
        end
    end

    methods (Static, Hidden)
        function info = emptyValues()
        %EMPTYVALUES Create an info struct with corresponding empty values
        % for each field name.
            emptyString = string.empty(0,1);
            emptyDouble = double.empty(0,1);
            info.Filename = emptyString;
            info.FileSize = emptyDouble;
            info.NumRowGroups = emptyDouble;
            info.RowGroupHeights = emptyDouble;
            info.VariableNames = emptyString;
            info.VariableTypes = emptyString;
            info.VariableCompression = emptyString;
            info.VariableEncoding = emptyString;
            info.Version = emptyString;
        end
    end

    methods (Hidden)
        function S = saveobj(obj)
        %saveobj   Save-to-struct for ParquetInfo.

            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 2);
            S.ClassVersion = obj.ClassVersion;

            % Public properties
            S.Filename            = obj.Filename;
            S.FileSize            = obj.FileSize;
            S.NumRowGroups        = obj.NumRowGroups;
            S.RowGroupHeights     = obj.RowGroupHeights;
            S.VariableNames       = obj.VariableNames;
            S.VariableTypes       = obj.VariableTypes;
            S.VariableCompression = obj.VariableCompression;
            S.VariableEncoding    = obj.VariableEncoding;
            S.Version             = obj.Version;
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(S)
            if ~isstruct(S)
                % This code path will only occur when loading ParquetInfo
                % from R2021a and older.
                % Normalize the loaded ParquetInfo and exit.
                obj = normalize(S);
                return;
            end

            import matlab.io.parquet.ParquetInfo;

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > ParquetInfo.ClassVersion
                    error(message("MATLAB:parquetio:read:UnsupportedClassVersion", "ParquetInfo"));
                end
            end

            % Manually set the expected properties and return.
            obj = matlab.io.parquet.ParquetInfo();
            obj = setProperties(obj, S);
        end
    end
end

function obj = setProperties(obj, internalObj)

    obj.Filename            = internalObj.Filename;
    obj.FileSize            = internalObj.FileSize;
    obj.NumRowGroups        = internalObj.NumRowGroups;
    obj.RowGroupHeights     = internalObj.RowGroupHeights;
    obj.VariableNames       = internalObj.VariableNames;
    obj.VariableTypes       = internalObj.VariableTypes;
    obj.VariableCompression = internalObj.VariableCompression;
    obj.VariableEncoding    = internalObj.VariableEncoding;
    obj.Version             = internalObj.Version;
end
