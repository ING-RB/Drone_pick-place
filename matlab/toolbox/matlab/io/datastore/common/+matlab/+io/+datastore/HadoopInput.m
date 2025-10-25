classdef (Sealed, Hidden) HadoopInput < handle & matlab.mixin.Copyable
    %HADOOPINPUT Input data described by a Hadoop InputFormat class.
    %
    %   INPUT = matlab.io.datastore.HadoopInput(CLASSNAME) creates an object
    %   that can be used to both partition and read data described by a Hadoop
    %   InputFormat class. CLASSNAME is the name of a Java class available on
    %   the Java classpath that implements org.apache.hadoop.mapreduce.InputFormat.
    %
    % HadoopInput Properties:
    %
    %   FormatClassname - Name of the Java class that implements
    %                     org.apache.hadoop.mapreduce.InputFormat
    %   Configuration   - Table of Key-Value pairs of Hadoop configuration
    %                     properties to be passed the input format object.
    %   ReadSize        - Number of Java values to return per read.
    %
    % HadoopInput Methods:
    %
    %   hasdata         - Returns true if there is unread data in the HadoopInput.
    %   read            - Read key-value pairs from the HadoopInput.
    %   reset           - Reset the HadoopInput to the start of the data.
    %   progress        - Percentage of HadoopInput data already read between 0.0 and 1.0.
    %   partition       - Returns a partitioned portion of the HadoopInput.
    %   maxpartitions   - Returns the maximum number of partitions for this HadoopInput.
    %   resolve         - Returns all the split information available in HadoopInput.
    %
    %   See also matlab.io.Datastore,
    %            matlab.io.datastore.Partitionable,
    %            matlab.io.datastore.HadoopLocationBased.
    
    %   Copyright 2018-2019 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        %FORMATCLASSNAME Name of the Java class that implements
        % org.apache.hadoop.mapreduce.InputFormat.
        FormatClassname
    end
    
    properties
        %CONFIGURATION Table of name-value pairs of Hadoop configuration
        % properties to be passed the input format object.
        Configuration
        
        % READSIZE Number of Java values to return per read.
        ReadSize = 1
    end
    
    properties (Access = private)
        % When partitioned, we store a copy of the partition inputs in
        % order to replicate the same HadoopInput after save/load. This is
        % necessary as all Java objects inside of HadoopInput are dropped
        % on save/load. To replicate the same HadoopInput, we store the
        % chain of partition invoke arguments necessary to replicate the
        % saved HadoopInput.
        PartitionChain (1, :) cell = {};
    end
    
    properties (Transient, Access = private)
        % An instance of org.apache.hadoop.Configuration associated with
        % the input format.
        ConfigurationObject = []
        
        % An instance of the input format class.
        %
        % This is initialized lazily to avoid issues in load/save.
        FormatObject = []
        
        % A cache of the input split array returned by
        % InputFormat/getSplits.
        %
        % This is initialized lazily to avoid issues in load/save.
        Splits = []
        
        % Index into Splits currently open for read.
        SplitIndex (1, 1) double = NaN
        
        % The current open RecordReader.
        %
        % This is initialized lazily to avoid issues in load/save.
        RecordReader = []
        
        % Number of records read from the current RecordReader.
        NumRecordsRead (1, 1) double = 0
    end
    
    % Constructor and Destructor
    methods
        % HadoopInput can be constructed with format classname, optionally
        % with Configuration and ReadSize name-value pairs.
        function obj = HadoopInput(classname, varargin)
            parser = inputParser;
            parser.FunctionName = "HadoopInput";
            parser.addParameter("Configuration", ...
                table(string.empty(0,1), string.empty(0,1), 'VariableNames', ["Key", "Value"]));
            parser.addParameter("ReadSize", 1);
            parser.parse(varargin{:});
            if ~matlab.internal.datatypes.isScalarText(classname)
                error(message("MATLAB:datastoreio:hadoopinput:invalidFormatClassname"));
            end
            obj.FormatClassname = string(classname);
            obj.Configuration = parser.Results.Configuration;
            obj.ReadSize = parser.Results.ReadSize;
            try
                obj.initConfigurationAndFormat();
            catch err
                throw(err);
            end
        end
        
        % The RecordReader might hold open file handles and other resources
        % that need to be closed.
        function delete(obj)
            obj.clearObjects();
        end
    end
    
    % Set methods for properties
    methods
        % Configuration must be a table containing "Key" and "Value" string
        % variables.
        function set.Configuration(obj, conf)
            if ~istable(conf)
                error(message("MATLAB:datastoreio:hadoopinput:invalidConfiguration"));
            end
            
            % Check validity of the Key variable
            if conf.Properties.DimensionNames{1} == "Key"
                % We're good
            elseif ~isempty(conf.Properties.RowNames)
                error(message("MATLAB:datastoreio:hadoopinput:invalidConfigurationRowDimName"));
            else
                if ~any(conf.Properties.VariableNames == "Key")
                    error(message("MATLAB:datastoreio:hadoopinput:invalidConfiguration"));
                end
                keys = flattenToString(conf.Key);
                checkForDuplicateKeys(keys);
                conf.Properties.RowNames = flattenToString(keys);
                conf.Key = [];
                conf.Properties.DimensionNames{1} = 'Key';
            end
            
            % Check validity of the Value variable
            if ~any(conf.Properties.VariableNames == "Value")
                error(message("MATLAB:datastoreio:hadoopinput:invalidConfiguration"));
            end
            conf.Value = flattenToString(conf.Value, "Value");
            
            obj.clearObjects();
            obj.Configuration = conf;
        end
        
        % ReadSize must be a positive integer scalar.
        function set.ReadSize(obj, readSize)
            if ~matlab.internal.datatypes.isScalarInt(readSize) ...
                    || ~isreal(readSize) ...
                    || readSize <= 0
                error(message("MATLAB:datastoreio:hadoopinput:invalidReadSize"));
            end
            obj.ReadSize = double(readSize);
        end
    end
    
    % Basic hasdata/read/reset/progress contract
    methods
        function tf = hasdata(obj)
            %HASDATA Returns true if there is unread data in the HadoopInput.
            %
            %   TF = HASDATA(HADOOPINPUT) returns true if HADOOPINPUT has one
            %   or more key-value pairs available to read with the read method.
            %
            %   See also matlab.io.datastore.HadoopInput, read, reset.
            try
                initNextReader(obj);
                tf = ~isempty(obj.RecordReader);
            catch err
                throw(err);
            end
        end
        
        function [keys, values, info] = read(obj)
            %READ Read key-value pairs from the HadoopInput.
            %
            %   [KEYS,VALUES] = READ(HADOOPINPUT) reads the next consecutive
            %   key-value pairs from HADOOPINPUT. This errors if there are no
            %   available key-value pairs.
            %
            %   [KEYS,VALUES,INFO] = READ(HADOOPINPUT) also returns a structure
            %   with additional information about the key-value PAIRS. The
            %   fields of INFO are:
            %     Split  - The InputSplit object describing where this key-value
            %              pair was read from.
            %     Offset - Index of the first key-value pair respective to the
            %              start of Split.
            %     Length - Number of key-value pairs read
            %
            %   See also matlab.io.datastore.HadoopInput, hasdata, reset.
            try
                initNextReader(obj);
            catch err
                throw(err);
            end
            if isempty(obj.RecordReader)
                error(message("MATLAB:datastoreio:hadoopinput:noMoreData"));
            end
            % This does not use the callJavaMethod helper methods as read
            % can be called in a tight loop. This is the part of the code
            % that requires to be performant.
            keys = cell(obj.ReadSize, 1);
            values = cell(obj.ReadSize, 1);
            try
                for ii = 1:obj.ReadSize
                    keys{ii} = obj.RecordReader.getCurrentKey();
                    values{ii} = obj.RecordReader.getCurrentValue();
                    hasMoreData = obj.RecordReader.nextKeyValue();
                    if ~hasMoreData
                        obj.closeRecordReader();
                        keys(ii + 1 : end) = [];
                        values(ii + 1 : end) = [];
                        break;
                    end
                end
            catch err
                % Check whether getCurrentKey / getCurrentValue issued the
                % error.
                [~] = callJavaMethod("getCurrentKey", obj.RecordReader);
                [~] = callJavaMethod("getCurrentValue", obj.RecordReader);
                % Otherwise assume it was nextKeyValue
                throwAsCaller(addCause(MException(message( ...
                    "MATLAB:datastoreio:hadoopinput:javaMethodException", ...
                    class(obj), "nextKeyValue", class(obj), err.message)), err));
            end
            numRecords = numel(keys);
            keys = vertcat(keys{:});
            values = vertcat(values{:});
            if nargout == 3
                info = struct( ...
                    "Split", obj.Splits(obj.SplitIndex), ...
                    "Offset", {obj.NumRecordsRead + 1}, ...
                    "Length", {numRecords});
            end
            obj.NumRecordsRead = obj.NumRecordsRead + numRecords;
        end
        
        function reset(obj)
            %RESET Reset the HadoopInput to the start of the data.
            %
            %   RESET(HADOOPINPUT) resets HADOOPINPUT to the beginning of the HadoopInput.
            %
            %   See also matlab.io.datastore.HadoopInput, hasdata, read.
            try
                obj.closeRecordReader();
                obj.SplitIndex = 0;
            catch err
                throw(err);
            end
        end
        
        function p = progress(obj)
            %PROGRESS Percentage of HadoopInput data already read between 0.0 and 1.0.
            %
            %   P = PROGRESS(HADOOPINPUT) returns a fraction between 0.0 and 1.0
            %   indicating progress.
            if isnumeric(obj.Splits)
                p = 0;
                return;
            end
            numSplits = numel(obj.Splits);
            numCompleteSplits = obj.SplitIndex;
            if ~isempty(obj.RecordReader)
                numCompleteSplits = numCompleteSplits - 1 ...
                    + callJavaMethod("getProgress", obj.RecordReader);
            end
            p = numCompleteSplits / numSplits;
        end
    end
    
    % Partitionable contract
    methods
        function N = maxpartitions(obj)
            %MAXPARTITIONS Returns the maximum number of partitions for this HadoopInput.
            %
            %   N = MAXPARTITIONS(HADOOPINPUT) returns the maximum number of partitions
            %   for HADOOPINPUT.
            %
            %   See also matlab.io.datastore.HadoopInput, partition.
            try
                initSplits(obj);
                N = numel(obj.Splits);
            catch err
                throw(err);
            end
        end
        
        function obj = partition(obj, type, idx)
            %PARTITION Returns a partitioned portion of the HadoopInput.
            %
            %   SUBINPUT = PARTITION(HADOOPINPUT,NUMPARTITIONS,INDEX) partitions
            %   HADOOPINPUT into NUMPARTITIONS parts and returns the partitioned
            %   HadoopInput, HADOOPINPUT, corresponding to INDEX. The maximum value of
            %   NUMPARTITIONS input can be obtained by using the NUMPARTITIONS function.
            %
            %   SUBINPUT = PARTITION(HADOOPINPUT,LOCATION) partitions HADOOPINPUT using
            %   table LOCATION, which must be a single row of the output of
            %   RESOLVE(HADOOPINPUT).
            %
            %   See also matlab.io.datastore.HadoopInput, maxpartitions.
            try
                if nargin == 3
                    obj = partitionByIndex(obj, type, idx);
                else
                    obj = partitionByLocation(obj, type);
                end
            catch err
                throw(err);
            end
        end
        
        function t = resolve(obj)
            %RESOLVE Returns all the split information available in HadoopInput.
            %
            % LOCATIONS = RESOLVE(HADOOPINPUT) returns all the split
            % information available in HADOOPINPUT as table LOCATIONS. Each
            % row represents a single partition.
            %
            %   See also matlab.io.datastore.HadoopInput, partition.
            initSplits(obj);
            hostnames = cell(numel(obj.Splits), 1);
            splits = obj.Splits;
            for ii = 1:numel(hostnames)
                hostnames{ii} = string(splits{ii}.getLocations());
                byteArrayStream = java.io.ByteArrayOutputStream;
                dataOutputStream = java.io.DataOutputStream(byteArrayStream);
                callJavaMethod("write", splits{ii}, dataOutputStream);
                splits{ii} = byteArrayStream.toByteArray();
            end
            t = table;
            t.Hostname = hostnames;
            t.SplitData = splits;
            t.SplitClassname(:) = string(class(obj.Splits{1}));
        end
    end
    
    % Copyable contract
    methods (Access = protected)
        function newobj = copyElement(obj)
            % We can reuse the same Format and Split objects because
            % HadoopInput treats them as immutable after configuration.
            % This is not true of the reader, we clear this for the copy by
            % resetting the output.
            newobj = copyElement@matlab.mixin.Copyable(obj);
            newobj.reset();
        end
    end
    
    methods (Access = private)
        function subobj = partitionByIndex(obj, N, idx)
            % PARTITION(HADOOPINPUT,NUMPARTITIONS,INDEX)
            validateattributes(N, {'double'}, ...
                {'scalar', 'positive', 'integer'}, ...
                'partition', 'NumPartitions');
            validateattributes(idx, {'double'}, ...
                {'scalar', 'positive', 'integer'}, ...
                'partition', 'Index');
            if idx > N
                error(message("MATLAB:datastoreio:hadoopinput:invalidPartitionIndex"));
            end
            splitIndices = pidgeonHole(idx, N, numel(obj.Splits));
            % We initialize the splits before making the copy as this can
            % optimize the initialization when partition is called many
            % times.
            initSplits(obj);
            subobj = copy(obj);
            subobj.Splits = subobj.Splits(splitIndices);
            subobj.PartitionChain{end + 1} = {N, idx};
        end
        
        function subobj = partitionByLocation(obj, location)
            % PARTITION(HADOOPINPUT,LOCATION)
            validateattributes(location, {'table'}, ...
                {'row'}, 'partition', 'Location');
            if any(~ismember(["SplitClassname", "SplitData"], location.Properties.VariableNames))
                error(message("MATLAB:datastoreio:hadoopinput:invalidLocationTable"));
            end
            byteArrayStream = java.io.ByteArrayInputStream(location.SplitData{1});
            dataInputStream = java.io.DataInputStream(byteArrayStream);
            split = buildJavaObject(location.SplitClassname);
            callJavaMethod("readFields", split, dataInputStream);
            initConfigurationAndFormat(obj);
            subobj = copy(obj);
            subobj.Splits = {split};
            subobj.PartitionChain = {{location}};
        end
        
        function initConfigurationAndFormat(obj)
            % Initialize the Apache Configuration object as well as the
            % InputFormat object corresponding to FormatClassname. This will
            % no-op if the objects are already initialized.
            if ~isempty(obj.FormatObject)
                return;
            end
            
            conf = buildJavaObject("org.apache.hadoop.conf.Configuration");
            keys = obj.Configuration.Key;
            values = obj.Configuration.Value;
            for ii = 1:numel(keys)
                conf.set(keys{ii}, values{ii});
            end
            
            format = buildJavaObject(obj.FormatClassname);
            if ~isa(format, "org.apache.hadoop.mapreduce.InputFormat")
                error(message("MATLAB:datastoreio:hadoopinput:invalidFormatClass"));
            end
            if isa(format, "org.apache.hadoop.conf.Configurable")
                callJavaMethod("setConf", format, conf);
            end
            obj.ConfigurationObject = conf;
            obj.FormatObject = format;
        end
        
        function initSplits(obj)
            % Initialize the Splits array. This will no-op if the object is
            % already initialized.
            if ~isnumeric(obj.Splits)
                return;
            end
            obj.initConfigurationAndFormat();
            % This is a necessary evil. The API of InputFormat only accepts
            % a JobContext. We could either implement that interface
            % ourselves, or use the Job object in exactly the same way as
            % other libraries (e.g. Spark).
            j = callJavaMethod("getInstance", ...
                "org.apache.hadoop.mapreduce.Job", obj.ConfigurationObject);
            splits = callJavaMethod("getSplits", obj.FormatObject, j);
            obj.Splits = cell(callJavaMethod("toArray", splits));
            obj.SplitIndex = 0;
            if ~isempty(obj.PartitionChain)
                subObj = obj;
                for ii = 1:numel(obj.PartitionChain)
                    subObj = partition(subObj, subObj.PartitionChain{ii}{:});
                end
                % Contract of partition is to return a new object and leave
                % the input unmodified. We need to copy the results of
                % partition back to obj.
                obj.Splits = subObj.Splits;
            end
        end
        
        function initNextReader(obj)
            % Initialize the next RecordReader object. This will no-op if
            % a RecordReader already exists or no more RecordReaders are
            % available.
            if ~isempty(obj.RecordReader)
                return;
            end
            obj.initSplits();
            while obj.SplitIndex < numel(obj.Splits)
                nextSplitIndex = obj.SplitIndex + 1;
                splitObj = obj.Splits{nextSplitIndex};
                % This is a necessary evil. The API of InputFormat accepts
                % a TaskAttemptContext only. We could either implement that
                % interface ourselves, or use the Impl object in exactly
                % the same way as other libraries (e.g. Spark).
                attemptId = buildJavaObject( ...
                    "org.apache.hadoop.mapreduce.TaskAttemptID", ...
                    "HadoopInput", 0, ...
                    getJavaEnum("org.apache.hadoop.mapreduce.TaskType", "MAP"), ...
                    nextSplitIndex, 0);
                hadoopAttemptContext = buildJavaObject( ...
                    "org.apache.hadoop.mapreduce.task.TaskAttemptContextImpl", ...
                    obj.ConfigurationObject, attemptId);
                % Common libraries require two steps for initialization:
                %Building a RecordReader requires two steps:
                %  1. Ask the Format class to build us a RecordReader
                %     object.
                %  2. Initialize the RecordReader (with the same info!)
                newRecordReader = callJavaMethod("createRecordReader", ...
                    obj.FormatObject, splitObj, hadoopAttemptContext);
                callJavaMethod("initialize", ...
                    newRecordReader, splitObj, hadoopAttemptContext);
                hasData = callJavaMethod("nextKeyValue", newRecordReader);
                obj.SplitIndex = nextSplitIndex;
                if hasData
                    obj.RecordReader = newRecordReader;
                    obj.NumRecordsRead = 0;
                    break;
                end
            end
        end
        
        function closeRecordReader(obj)
            % Close an open RecordReader. This gives the RecordReader a
            % chance to delete open resources such as file handles.
            if isempty(obj.RecordReader)
                return;
            end
            recordReader = obj.RecordReader;
            obj.RecordReader = [];
            callJavaMethod("close", recordReader);
        end
        
        function clearObjects(obj)
            % Clear all Java objects from properties. This allows these
            % objects to be reinitialized with new configuration.
            obj.closeRecordReader();
            obj.Splits = [];
            obj.FormatObject = [];
            obj.ConfigurationObject = [];
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function splitIndices = pidgeonHole(partitionIndex, numPartitions, numSplits)
% Helper function that chooses a collection of split indices based on
% a partition index and number of partitions.
transformedSplitIndices = floor((0:numSplits - 1) * numPartitions / numSplits) + 1;
splitIndices = find(transformedSplitIndices == partitionIndex);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = flattenToString(data, varName)
% Flatten the given array to string. This is required as Configuration only
% supports string key-value pairs.
try
    data = string(data);
catch err
    throwAsCaller(addCause(MException(message( ...
        "MATLAB:datastoreio:hadoopinput:invalidConfigurationVarType", varName)), err));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function checkForDuplicateKeys(keys)
% Check if the given keys array contain duplicate values. Duplicates are
% not allowed in the Key variable of Configuration.
[uniqueKeys, ~, idx] = unique(keys);
if numel(keys) ~= numel(uniqueKeys)
    counts = accumarray(idx, 1);
    dupIdx = find(counts > 1, 1);
    throwAsCaller(MException(message( ...
        "MATLAB:datastoreio:hadoopinput:duplicateConfigurationKey", uniqueKeys(dupIdx))));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obj = getJavaEnum(clz, enum)
% Helper class around Java enums that ensures any errors from the
% underlying Java classes point to the class/method.
checkClassExists(clz);
obj = callJavaMethod("valueOf", clz, enum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obj = buildJavaObject(clz, varargin)
% Helper class around javaObject that ensures any errors from the
% underlying Java classes point to the class/method.
checkClassExists(clz);
try
    obj = javaObject(clz, varargin{:});
catch err
    throwAsCaller(addCause(MException(message( ...
        "MATLAB:datastoreio:hadoopinput:javaConstructException", ...
        clz, ...
        class(err.ExceptionObject), string(err.ExceptionObject.getMessage()))), err))
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function checkClassExists(clz)
if exist(clz, "class") ~= 8
    throwAsCaller(MException(message( ...
        "MATLAB:datastoreio:hadoopinput:missingJavaClass", clz)));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = callJavaMethod(method, obj, varargin)
% Helper class around javaMethod that ensures any errors from the
% underlying Java classes point to the class/method.
try
    if nargout
        out = javaMethod(method, obj, varargin{:});
    else
        javaMethod(method, obj, varargin{:});
    end
catch err
    clz = obj;
    if ~matlab.internal.datatypes.isScalarText(clz)
        clz = class(clz);
    end
    throwAsCaller(addCause(MException(message( ...
        "MATLAB:datastoreio:hadoopinput:javaMethodException", ...
        clz, method, ...
        class(err.ExceptionObject), char(err.ExceptionObject.getMessage()))), err));
end
end
