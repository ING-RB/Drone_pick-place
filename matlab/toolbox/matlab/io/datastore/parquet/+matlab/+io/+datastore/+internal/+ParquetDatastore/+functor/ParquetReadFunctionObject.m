classdef ParquetReadFunctionObject < matlab.mixin.internal.FunctionObject ...
                                   & matlab.mixin.Copyable
%ParquetReadFunctionObject   Executes parquetread while also keeping the
%   ParquetImportOptions accessible.

%   Copyright 2022 The MathWorks, Inc.

    properties
        ImportOptions (1, 1) matlab.io.parquet.internal.ParquetImportOptions
    end

    methods
        function func = ParquetReadFunctionObject(pio)
            func.ImportOptions = pio;
        end

        function [data, info] = parenReference(func, reader, info)
            arguments
                func
                reader
                info (1, 1) struct
            end

            [info, rowgroups] = fixInfoStruct(info, reader);

            import matlab.io.parquet.internal.parquetread2
            data = parquetread2(reader, func.ImportOptions, RowGroups=rowgroups);
        end
    end

    % Save-load logic.
    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ParquetDatastore in R2022b.
        ClassVersion (1, 1) double = 1;
    end

    methods
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % State properties
            S.ImportOptions = obj.ImportOptions;
        end
    end

    methods (Static)
        function obj = loadobj(S)

            import matlab.io.datastore.internal.ParquetDatastore.functor.ParquetReadFunctionObject

            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > ParquetReadFunctionObject.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            obj = ParquetReadFunctionObject(S.ImportOptions);
        end
    end
end

function [info, rowgroups] = fixInfoStruct(info, reader)
    if isfield(info, "RepetitionIndex")
        % RowGroup mode. Just read the current RepetitionIndex.
        rowgroups = info.RepetitionIndex;
        info = rmfield(info, "RepetitionIndex");
    else
        % File mode. Read all the rowgroups in the file.
        rowgroups = 1:reader.InternalReader.NumRowGroups;
    end

    % The info struct needs to have a RowGroups property.
    info.RowGroups = rowgroups;
end
