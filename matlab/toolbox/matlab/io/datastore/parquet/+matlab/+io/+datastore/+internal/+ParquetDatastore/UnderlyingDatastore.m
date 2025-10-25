classdef UnderlyingDatastore < matlab.io.datastore.internal.ComposedDatastore
%ParquetDatastore2.UnderlyingDatastore   Common requirements for any
%   datastore underlying ParquetDatastore2:
%
%    - Must be a ComposedDatastore
%    - Must have a ParquetImportOptions
%    - Must be backed by a matlab.io.datastore.internal.FileDatastore2
%    - Must have a SchemaDatastore in the stack.
%    - Must declare a "ReadSize" value.
%    - Must declare a "PartitionMethod" value.
%
%   Make sure that any subclass is in a consistent state after setting ImportOptions
%   or FileSet, both of which will probably require a reset().

%   Copyright 2022-2023 The MathWorks, Inc.

    properties (Abstract)
        ImportOptions (1, 1) matlab.io.parquet.internal.ParquetImportOptions
    end

    properties (Dependent, SetAccess=private)
        FileSet
    end

    methods
        function fs = get.FileSet(obj)
        % These datastores should always have a FileDatastore2
        % underlying them.
            fs = obj.getUnderlyingDatastore("matlab.io.datastore.internal.FileDatastore2").FileSet;
        end
    end

    properties (Dependent, SetAccess=private)
        % Cannot just set the schema since that should only be done with a
        % change to the ParquetImportOptions.
        Schema
    end

    methods
        function schema = get.Schema(obj)
        % These datastores should always have a SchemaDatastore
        % underlying them.
            schema = getUnderlyingDatastore(obj, "matlab.io.datastore.internal.SchemaDatastore").Schema;
        end
    end

    % Use this property to declare the current ReadSize.
    properties (Abstract, SetAccess=private)
        ReadSize
    end

    properties (Abstract, SetAccess=private)
        PartitionMethod
    end

    % Shared save-load logic. Subclasses should override this if they have any
    % other concrete properties apart from UnderlyingDatastore.
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
            S.UnderlyingDatastore = obj.UnderlyingDatastore;
        end
    end

    methods (Static)
        function obj = loadobj(S)
            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.ClassVersion
                    error(message("MATLAB:io:datastore:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct the object.
            % Unfortunately, since this needs knowledge of the subclass constructor,
            % each subclass needs to implement this manually.
            obj = [];
        end
    end
end
