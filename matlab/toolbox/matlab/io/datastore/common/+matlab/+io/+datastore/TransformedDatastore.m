classdef TransformedDatastore < matlab.io.Datastore ...
                              & matlab.mixin.Copyable ...
                              & matlab.io.datastore.FileWritable ...
                              & matlab.io.datastore.mixin.Subsettable ...
                              & matlab.mixin.CustomDisplay

%TransformedDatastore  A Datastore that represents an underlying
%datastore type with functional transformations applied after read.
%
%   NEWDS = matlab.io.datastore.TransformedDatastore(DS,FUN) takes an
%   input datastore, DS, and a function, FUN, and returns a new
%   datastore instance, NEWDS, in which FUN is called on the output of
%   read from DS and returned as the output of read in NEWDS.
%   Conceptually, NEWDS is a transformed version of DS. On
%   construction, TransformedDatastore makes a copy of DS and calls
%   reset on the copy held in the UnderlyingDatastores property.
%
%   TransformedDatastore Methods:
%
%   preview         -    Read the subset of data from the datastore that is
%                        returned by the first call to the read method.
%   read            -    Read subset of data from the datastore.
%   readall         -    Read all of the data from the datastore.
%   hasdata         -    Returns true if there is more data in the datastore.
%   reset           -    Reset the datastore to the start of the data.
%   combine         -    Form a single datastore from multiple input
%                        datastores.
%   transform       -    Define a function which alters the underlying data
%                        returned by the read() method.
%   shuffle         -    Return a new TransformedDatastore that shuffles 
%                        all the data in the underlying datastores.
%   partition       -    Return a new TransformedDatastore that contains
%                        a single partitioned part of the original 
%                        underlying datastores.
%   numpartitions   -    Return an estimate for a reasonable number of
%                        partitions to use with the partition function.
%   writeall        -    Writes all the data in the datastore to a new 
%                        output location.
%
%   TransformedDatastore Properties:
%
%   UnderlyingDatastores    -   The original Datastore on which the
%                               Transforms will be applied to form the
%                               final output of read.
%
%   Transforms              -   Cell array which contains each of the
%                               transform functions which will be applied
%                               to the UnderlyingDatastores to form the
%                               final output of read.
%
%   IncludeInfo             -   Logical vector which defines whether info
%                               is part of the transform function
%                               definition for each function in
%                               Transforms.
%
%   SupportedOutputFormats  -   List of formats supported for writing
%                               by this datastore.
%
%   See also matlab.io.Datastore.transform, matlab.io.Datastore.combine

%   Copyright 2018-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        %UnderlyingDatastores The datastores being transformed
        UnderlyingDatastores (1,:) cell
    end

    properties (Constant)
        SupportedOutputFormats = matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SupportedOutputFormats;
    end

    properties (Constant, Hidden)
        DefaultOutputFormat = string(missing);
    end

    properties (Dependent, Hidden, SetAccess = private)
        %UnderlyingDatastore For backward compatibility
        UnderlyingDatastore
    end

    properties (SetAccess = private)
        % TRANSFORMS - The set of transformations that will be applied,
        % from first to last, to the UnderlyingDatastores, to form the
        % result of read.
        Transforms = {}

        % INCLUDEINFO - A logical array which defines how each
        % corresponding function in Transforms will be called in terms of
        % whether or not the info from read should be part of the input and
        % output function signature of the function in Transforms.
        IncludeInfo = logical.empty();
    end

    methods

        function ds = TransformedDatastore(datastoresIn,fun,includeInfo)
        %TransformedDatastore Construct a TransformedDatastore object
        %
        %   DSOUT = TransformedDatastore(DS,FUN) creates a
        %   TransformedDatastore object given input Datastore, DS,
        %   and a function_handle, FUN.
        %
        %   DSOUT = TransformedDatastore(DSCELL, FUN) creates a
        %   TransformedDatastore that applies FUN to the data in multiple
        %   input datastores. FUN must have the signature:
        %
        %       output = FUN(DS1_data, DS2_data, ... DSN_data);
        %
        %   where N is the number of datastores provided in DSCELL.
        %
        %   DSOUT = TransformedDatastore(DS,FUN,INCLUDEINFO) creates a
        %   TransformedDatastore in which the optional argument
        %   INCLUDEINFO defines how FUN will be called. Here, DS can either
        %   be a single datastore or a cell array of multiple datastores.
        %   When INCLUDEINFO is false, the default, FUN will be called as
        %   follows:
        %
        %       dataOut = transformFcn(dataIn)
        %
        %   When INCLUDEINFO is true, FUN will be called:
        %
        %       [dataOut,infoOut] = transformFcn(dataIn,infoIn)
        %
        %   See also: matlab.io.Datastore.transform, imageDatastore
            
            if nargin > 0
                validateDatastore = @(ds) validateattributes(ds, ...
                    ["matlab.io.Datastore", "matlab.io.datastore.Datastore"],...
                    "scalar", "matlab.io.datastore.TransformedDatastore");

                if iscell(datastoresIn)
                    cellfun(validateDatastore, datastoresIn);
                    dsCopies = cellfun(@copy, datastoresIn, "UniformOutput", false);
                    ds.UnderlyingDatastores = dsCopies;
                else
                    if isa(datastoresIn,"matlab.io.datastore.TransformedDatastore")
                        ds = copy(datastoresIn);
                    else
                        validateDatastore(datastoresIn);
                        ds.UnderlyingDatastores = {copy(datastoresIn)};
                    end
                end
            end

            if nargin > 1
                import matlab.io.datastore.internal.functor.isConvertibleToFunctionObject
                if ~isConvertibleToFunctionObject(fun)
                    % Throw a validateattributes error that only mentions function_handle.
                    classes = "function_handle";
                    attributes = "scalar";
                    validateattributes(fun, classes, attributes, ...
                        "matlab.io.datastore.TransformedDatastore");
                end

                if isa(fun, "function_handle")
                    tFuncArgs = nargin(fun);
                else
                    % No clear nargin on FunctionObject yet.
                    tFuncArgs = -1;
                end

                if nargin > 2
                    % check that IncludeInfo value is logical
                    if(~islogical(includeInfo) && ~isnumeric(includeInfo))
                        error(message("MATLAB:matrix:singleSubscriptNumelMismatch"));
                    end
                else
                    includeInfo = false;
                end

                if includeInfo
                    numInputs = 2*numel(datastoresIn);
                else
                    numInputs = numel(datastoresIn);
                end
                if iscell(datastoresIn) && tFuncArgs > 0 && ...
                        tFuncArgs ~= numInputs
                    if includeInfo
                        error(message("MATLAB:datastoreio:transformeddatastore:wrongNumInputsToTransformPlusIncludeInfo", ...
                            tFuncArgs, numInputs));
                    else
                        error(message("MATLAB:datastoreio:transformeddatastore:wrongNumInputsToTransform", ...
                            tFuncArgs, numInputs));
                    end
                end
                ds.Transforms{end+1} = fun;
            end

            if nargin > 2
                ds.IncludeInfo(end+1) = includeInfo;
            else
                % Default if unspecified in constructor call
                ds.IncludeInfo(end+1) = false;
            end

            % Ensure that iterator state on all underlying datastores is
            % reset whenever we construct a TransformedDatastore.
            reset(ds);
        end

        function s = saveobj(self)
            s.UnderlyingDatastores = self.UnderlyingDatastores;
            s.Transforms = self.Transforms;
            s.IncludeInfo = self.IncludeInfo;
            s.SupportedOutputFormats = self.SupportedOutputFormats;
        end

        function [data, info] = read(ds)
        %READ   Read data and information about the extracted data
        %
        %   Return the data read from the underlying datastores after 
        %   applying the function handles listed in the Transforms property.
        %
        %   Also returns the second output argument of the underlying
        %   datastores' read function. If IncludeInfo was set to true, then
        %   the second output argument may have been modified by the
        %   functions listed in the Transforms property.
        %
        %   See also hasdata, reset, readall, preview
            if ~hasdata(ds)
                error(message('MATLAB:datastoreio:splittabledatastore:noMoreData'));
            end

            numDatastores = numel(ds.UnderlyingDatastores);
            if numDatastores > 1 
                data = cell(1, numDatastores);
                info = cell(1, numDatastores);
                for ii = 1 : numDatastores
                    [data{ii}, info{ii}] = read(ds.UnderlyingDatastores{ii});
                end
            else
                [data, info] = read(ds.UnderlyingDatastores{1});
            end

            [data, info] = ds.applyTransforms(data, info);
        end

        function reset(ds)
        %RESET   Reset the underlying datastores to the start of data
        %
        %   See also: hasdata, read
            for ii = 1 : numel(ds.UnderlyingDatastores)
                reset(ds.UnderlyingDatastores{ii});
            end
        end

        function tf = hasdata(ds)
        %HASDATA   Returns true if more data is available to read
        %
        %   Return a logical scalar indicating availability of data. This
        %   method should be called before calling read.
        %
        %   See also: reset, read
            if isempty(ds.UnderlyingDatastores)
                tf = false;
            else
                tf = true;
                for ii = 1 : numel(ds.UnderlyingDatastores)
                    if ~hasdata(ds.UnderlyingDatastores{ii})
                        tf = false;
                        break;
                    end
                end
            end
        end

        function data = readall(ds, varargin)
        %READALL   Attempt to read all data from the datastore
        %
        %   DATA = READALL(DS) returns all of the data contained within
        %   this datastore.
        %
        %   DATA = READALL(DS, "UseParallel", TF) specifies whether a parallel
        %   pool is used to read all of the data. By default, "UseParallel" is
        %   set to false.
        %
        %   See also read, hasdata, reset, preview

            if matlab.io.datastore.read.validateReadallParameters(varargin{:})
                data = matlab.io.datastore.read.readallParallel(ds);
                return;
            end

            copyds = copy(ds);
            reset(copyds);

            if ~hasdata(copyds)
                % We can't actually know the number of columns that would
                % result from an empty datastore since we can't call read,
                % so we can't call: cell.empty(0,numCols), since we don't
                % know numCols.
                data = {};
                return
            end

            % Read into a cell and vertcat at the end to reduce incremental
            % vertcat overhead.
            data = cell.empty(0, 1);
            while hasdata(copyds)
                data{end+1} = read(copyds); %#ok<AGROW>
            end
            data = vertcat(data{:});
        end

        function data = preview(ds)
        %PREVIEW   Preview the data contained in the datastore.
        %   Returns a small amount of data from the start of the datastore.
        %
        %   DATA = PREVIEW(DS) returns a small amount of data from the
        %   datastore.
        %
        %   See also matlab.io.Datastore, read, hasdata, reset, readall

            copyds = copy(ds);
            reset(copyds);
            dataFromRead = read(copyds);

            if istable(dataFromRead) || iscell(dataFromRead)
                % Return no more than 8 rows of data
                otherDims = repmat({':'}, 1, ndims(dataFromRead) - 1);
                numRows = min(8,size(dataFromRead,1));
                substr = substruct('()', [{1:numRows}, otherDims]);
                data = subsref(dataFromRead, substr);
            else
                % Just verbatim return the first read
                data = dataFromRead;
            end
        end

        function tf = isPartitionable(ds)
        %isPartitionable   returns true if this datastore is partitionable
        %
        %   The underlying datastore must be partitionable in order for a 
        %   TransformedDatastore to be partitionable.
        %
        %   See also: isShuffleable, partition, numpartitions

            if isempty(ds.UnderlyingDatastores)
                % Consider an empty TransformedDatastore to be
                % partitionable.
                tf = true;
            elseif numel(ds.UnderlyingDatastores) > 1
                % Check whether the underlying datastores are subsettable
                tf = true;
                for ii = 1 : numel(ds.UnderlyingDatastores)
                    if ~isSubsettable(ds.UnderlyingDatastores{ii})
                        tf = false;
                        break;
                    end
                end
            else
                % Check whether the underlying datastore is partitionable
                tf = ds.UnderlyingDatastores{1}.isPartitionable();
            end
        end

        function tf = isShuffleable(ds)
        %isShuffleable   returns true if this datastore is shuffleable
        %
        %   The underlying datastore must be shuffleable in order for a 
        %   TransformedDatastore to be shuffleable.
        %
        %   See also: isPartitionable, shuffle

            if isempty(ds.UnderlyingDatastores)
                % Consider an empty TransformedDatastore to be
                % shuffleable.
                tf = true;
            elseif numel(ds.UnderlyingDatastores) > 1
                % Check whether the underlying datastores are subsettable
                tf = true;
                for ii = 1 : numel(ds.UnderlyingDatastores)
                    if ~isSubsettable(ds.UnderlyingDatastores{ii})
                        tf = false;
                        break;
                    end
                end
            else
                % Check whether underlying datastore is shuffleable
                tf = ds.UnderlyingDatastores{1}.isShuffleable();
            end
        end

        function shufds = shuffle(ds)
        %SHUFFLE    Return a shuffled version of this TransformedDatastore
        %
        %   NEWDS = SHUFFLE(DS) returns a randomly shuffled copy of a
        %   datastore.
        %
        %   A TransformedDatastore is only shuffleable when its
        %   UnderlyingDatastores are shuffleable. The isShuffleable method
        %   indicates whether a datastore is shuffleable or not.
        %
        %   See also isShuffleable, matlab.io.datastore.Shuffleable

            ds.verifyShuffleable("shuffle");

            if isempty(ds.UnderlyingDatastores)
                % Return a trivial copy if the underlying datastores are
                % empty.
                shufds = copy(ds);
            elseif numel(ds.UnderlyingDatastores) > 1
                ds.verifySubsettable("shuffle");
                shufds = shuffle@matlab.io.datastore.mixin.Subsettable(ds);
            else
                shufds = iConstructWithNewUnderlyingDatastore(...
                    {ds.UnderlyingDatastores{1}.shuffle()}, ds);
            end
        end

        % Overriding writeall to customize m-help.
        function writeall(ds, location, varargin)
            %WRITEALL    Read all the data in the datastore and write to disk
            %   WRITEALL(DS, OUTPUTLOCATION, "OutputFormat", FORMAT) 
            %   writes files using the specified output format. The allowed 
            %   FORMAT values are: 
            %     - Tabular formats: "txt", "csv", "xlsx", "xls",
            %     "parquet", "parq"
            %     - Image formats: "png", "jpg", "jpeg", "tif", "tiff"
            %     - Audio formats: "wav", "ogg", "opus", "flac", "mp4", 
            %                      "m4a"
            %
            %   WRITEALL(__, "FolderLayout", LAYOUT) specifies whether folders
            %   should be copied from the input data locations. Specify
            %   LAYOUT as one of these values:
            %
            %     - "duplicate" (default): Input files are written to the output
            %       folder using the folder structure under the folders listed
            %       in the first files-based UnderlyingDatastores' 
            %       "Folders" property.
            %
            %     - "flatten": Files are written directly to the output
            %       location without generating any intermediate folders.
            %   
            %   WRITEALL(__, "UseParallel", TF) specifies whether a parallel
            %   pool is used to write data. By default, "UseParallel" is 
            %   set to false.
            %
            %   WRITEALL(__, "FilenamePrefix", PREFIX) specifies a common
            %   prefix to be applied to the output file names.
            %
            %   WRITEALL(__, "FilenameSuffix", SUFFIX) specifies a common
            %   suffix to be applied to the output file names.
            %
            %   WRITEALL(DS, OUTPUTLOCATION, "WriteFcn", @MYCUSTOMWRITER) 
            %   customizes the function that is executed to write each 
            %   file. The signature of the "WriteFcn" must be similar to:
            %      
            %      function MYCUSTOMWRITER(data, writeInfo, outputFmt, varargin)
            %         ...
            %      end
            %
            %   where 'data' is the output of the read method on the
            %   datastore, 'outputFmt' is the output format to be written,
            %   and 'writeInfo' is a struct containing the
            %   following fields:
            %
            %     - "ReadInfo": the second output of the read method.
            %
            %     - "SuggestedOutputName": a fully qualified, unique file
            %       name that meets the location and naming requirements.
            %
            %     - "Location": the location argument passed to the write
            %       method.
            %   Any optional Name-Value pairs can be passed in via varargin.
            %
            %   See also: matlab.io.datastore.TransformedDatastore
            import matlab.io.datastore.write.*;
            import matlab.io.datastore.internal.write.utility.iFindCorrectFileSep;
            try
                % Validate the location input first.
                location = validateOutputLocation(ds, location);
                ds.OrigFileSep = iFindCorrectFileSep(location);

                % if this datastore is backed by files, get list of files
                files = getFiles(ds);

                % if this datastore is backed by files, get list of folders
                folders = getFolders(ds);

                % Set up the name-value pairs
                nvStruct = parseWriteallOptions(ds, varargin{:});

                % Check if the underlying datastore initialized
                % SupportedOutputFormats
                try
                    underlyingFmts = getUnderlyingSupportedOutputFormats(ds);
                catch
                    underlyingFmts = [];
                end
                outFmt = [ds.SupportedOutputFormats, underlyingFmts];

                % Validate the name-value pairs
                nvStruct = validateWriteallOptions(ds, folders, nvStruct, outFmt);

                % Construct the output folder structure.
                createFolders(ds, location, folders, nvStruct.FolderLayout);

                % Write using a serial or parallel strategy.
                writeParallel(ds, location, files, nvStruct);
            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function partds = partition(ds, n, index)
        %PARTITION   Return a TransformedDatastore containing a part of the
        %   underlying datastore.
        %
        %   SUBDS = PARTITION(DS, N, INDEX) partitions DS into
        %   N parts and returns the partitioned Datastore, SUBDS,
        %   corresponding to INDEX. An estimate for a reasonable
        %   value for N can be obtained by using the NUMPARTITIONS
        %   function.
        %
        %   A TransformedDatastore is only partitionable when its
        %   UnderlyingDatastores are partitionable. The isPartitionable
        %   method indicates whether a TransformedDatastore is partitionable
        %   or not.
        %
        %   See also: isPartitionable, numpartitions

            ds.verifyPartitionable("partition");

            if isempty(ds.UnderlyingDatastores)
                % Return a trivial partition if the underlying datastore is
                % empty.
                validateattributes(n, {'numeric'}, {'scalar', 'integer', 'positive'}, ...
                    "partition", "NumPartitions");
                validateattributes(index, {'numeric'}, {'scalar', 'integer', ...
                    'positive', '<=', n}, "partition", "PartitionIndex");
                partds = copy(ds);
            elseif numel(ds.UnderlyingDatastores) > 1
                ds.verifySubsettable("partition");
                partds = partition@matlab.io.datastore.mixin.Subsettable(ds, n, index);
            else
                underlyingPartition = ds.UnderlyingDatastores{1}.partition(n, index);
                partds = iConstructWithNewUnderlyingDatastore({underlyingPartition}, ds);
            end
        end

        function value = get.UnderlyingDatastore(ds)
            % getter for the dependent UnderlyingDatastore property
            if ~isempty(ds.UnderlyingDatastores)
                value = ds.UnderlyingDatastores{1};
            else
                value = [];
            end
        end

        function tf = isSubsettable(ds)
        %isSubsettable    returns true if this datastore is subsettable
        %
        %   The underlying datastores must be subsettable in order for a 
        %   TransformedDatastore to be subsettable.
        %
        %   See also: isPartitionable, subset, numobservations

            if isempty(ds.UnderlyingDatastores)
                % An empty TransformedDatastore can be considered to be
                % subsettable.
                tf = true;
            else
                tf = all(cellfun(@isSubsettable, ds.UnderlyingDatastores));
            end
        end

        function subds = subset(ds, indices)
        %SUBSET   returns a new TransformedDatastore containing the 
        %   specified observation indices
        %
        %   SUBDS = SUBSET(DS, INDICES) creates a deep copy of the input
        %   datastore DS containing observations corresponding to INDICES.
        %
        %   It is only valid to call the SUBSET method on a
        %   TransformedDatastore if it returns isSubsettable true.
        %
        %   INDICES must be a vector of positive and unique integer numeric
        %   values. INDICES can be a 0-by-1 empty array and does not need 
        %   to be provided in any sorted order when nonempty.
        %
        %   The output datastore SUBDS, contains the observations
        %   corresponding to INDICES and in the same order as INDICES.
        %
        %   INDICES can also be specified as a N-by-1 vector of logical
        %   values, where N is the number of observations in the datastore.
        %
        %   See also matlab.io.Datastore.isSubsettable, 
        %   matlab.io.datastore.mixin.Subsettable.numobservations, 
        %   matlab.io.datastore.ImageDatastore.subset

            ds.verifySubsettable("subset");

            import matlab.io.datastore.internal.validators.validateSubsetIndices;
            try
                indices = validateSubsetIndices(indices, ds.numobservations(), ...
                    'TransformedDatastore', false);
            catch ME
                % Provide a more accurate error message in the empty subset case.
                if ME.identifier == "MATLAB:datastoreio:splittabledatastore:zeroSubset"
                    msgid = "MATLAB:datastoreio:combineddatastore:zeroSubset";
                    error(message(msgid, "TransformedDatastore"));
                end
                throw(ME)
            end

            if isempty(ds.UnderlyingDatastores)
                % Return the trivial subset, which would just be a copy of 
                % the empty TransformedDatastore.
                subds = copy(ds);
            elseif numel(ds.UnderlyingDatastores) > 1
                % Forward to underlying datastores' subset methods
                fcn = @(ds) ds.subset(indices);
                subds = cellfun(fcn, ds.UnderlyingDatastores, ...
                    "UniformOutput", false);
                subds = iConstructWithNewUnderlyingDatastore(subds, ds);
            else
                subds = iConstructWithNewUnderlyingDatastore(...
                    {ds.UnderlyingDatastores{1}.subset(indices)}, ds);
            end
        end
    end

    methods(Access = {?matlab.io.datastore.FileWritable, ...
            ?matlab.bigdata.internal.executor.FullfileDatastorePartitionStrategy})
        function files = getFiles(ds)
            files = {};
            for idx = 1:numel(ds.UnderlyingDatastores)
                try
                    files = getFiles(ds.UnderlyingDatastores{idx});
                    return;
                catch
                end
            end
            if isempty(files)
                error(message("MATLAB:io:datastore:write:write:NotBackedByFiles"));
            end
        end

        function outFmts = getUnderlyingSupportedOutputFormats(ds)
            outFmts = [];
            for idx = 1:numel(ds.UnderlyingDatastores)
                if isa(ds.UnderlyingDatastores{idx}, ...
                        "matlab.io.datastore.CombinedDatastore") || ...
                        isa(ds.UnderlyingDatastores{idx}, ...
                        "matlab.io.datastore.TransformedDatastore") || ...
                        isa(ds.UnderlyingDatastores{idx}, ...
                        "matlab.io.datastore.SequentialDatastore")
                    outFmts = [outFmts, ...
                        getUnderlyingSupportedOutputFormats(ds.UnderlyingDatastores{idx})]; %#ok<AGROW>
                else
                    outFmts = [outFmts, ...
                        ds.UnderlyingDatastores{idx}.SupportedOutputFormats]; %#ok<AGROW>
                end
            end
            outFmts = unique(outFmts);
        end
    end

    methods(Access = protected)
        function folders = getFolders(ds)
            folders = {};
            for idx = 1:numel(ds.UnderlyingDatastores)
                try
                    folders = getFolders(ds.UnderlyingDatastores{idx});
                    return;
                catch
                end
            end
        end

        function filename = getCurrentFilename(~, info)
            %GETCURRENTFILENAME Get the current file name
            %   Get the name of the file read by the datastore
            if iscell(info)
                if isfield(info{1}, "Filename")
                    filename = string(info{1}.Filename);
                else
                    filename = "";
                end
            elseif isfield(info, "Filename")
                filename = string(info.Filename);
            else
                filename = "";
            end
        end

        function tf = currentFileIndexComparator(ds, currFileIndex)
            tf = false;
            for idx = 1:numel(ds.UnderlyingDatastores)
                try
                    tf = currentFileIndexComparator(ds.UnderlyingDatastores{idx}, currFileIndex);
                    return;
                catch
                end
            end
        end

        function [data, info] = applyTransforms(ds, data, info)
        %applyTransforms   A helper method to apply the Transforms list to
        %   the data and info read from the underlying datastores.

            for ii = 1 : length(ds.Transforms)
                try
                    if ds.IncludeInfo(ii)
                        if ii == 1 && numel(ds.UnderlyingDatastores) > 1
                            % enter this branch for the first transform that can
                            % accept multiple inputs from underlying datastores
                            [data, info] = ds.Transforms{ii}(data{:}, info{:});
                        else
                            [data, info] = ds.Transforms{ii}(data, info);
                        end
                    else
                        if ii == 1 && numel(ds.UnderlyingDatastores) > 1
                            % enter this branch for the first transform that can
                            % accept multiple inputs from underlying datastores
                            data = ds.Transforms{ii}(data{:});
                        else
                            data = ds.Transforms{ii}(data);
                        end
                    end
                catch ME
                    newException = matlab.io.datastore.exceptions.TransformException();
                    newException = newException.addCause(ME);
                    throwAsCaller(newException);
                end
            end
        end

        function dsnew = copyElement(ds)
            dsnew = copyElement@matlab.mixin.Copyable(ds);
            if ~isempty(ds.UnderlyingDatastores)
                dsnew.UnderlyingDatastores = cellfun(@copy, ...
                    ds.UnderlyingDatastores, "UniformOutput", false);
            end

            % Also deep-copy any FunctionObjects that are in the
            % Transforms list.
            function x = deepCopyIfPossible(x)
                if isa(x, "matlab.mixin.Copyable")
                    x = x.copy();
                end
            end

            if ~isempty(ds.Transforms)

                dsnew.Transforms = cellfun(@deepCopyIfPossible, ds.Transforms, ...
                    UniformOutput=false);
            end
        end

        function n = maxpartitions(ds)
        %MAXPARTITIONS Return the maximum number of partitions
        %   possible for the datastore.

            ds.verifyPartitionable("numpartitions");

            % Handle the empty case separately.
            if isempty(ds.UnderlyingDatastores)
                n = 0;
            elseif numel(ds.UnderlyingDatastores) > 1
                % numpartitions with no additional inputs returns the maximum
                % number of partitions on the underlying datastores.
                ds.verifySubsettable("numpartitions");
                n = ds.numobservations();
            else
                % numpartitions with no additional inputs returns the maximum
                % number of partitions on the underlying datastore.
                n = ds.UnderlyingDatastores{1}.numpartitions();
            end
        end

        function displayScalarObject(ds)
            disp(getHeader(ds));
            group = getPropertyGroups(ds);
            group.PropertyList = rmfield(group.PropertyList, "UnderlyingDatastores");
            dsIsEmpty = isempty(ds.UnderlyingDatastores);
            if dsIsEmpty
                fprintf("      UnderlyingDatastores: []\n");
            else
                fprintf("      UnderlyingDatastores: {");
            end
            for ii = 1 : min(numel(ds.UnderlyingDatastores), 3) - 1
                fprintf("%s,  ", class(ds.UnderlyingDatastores{ii}));
            end
            if numel(ds.UnderlyingDatastores) > 3
                fprintf("%s, ... and %d more}\n", ...
                    class(ds.UnderlyingDatastores{ii+1}), ...
                    numel(ds.UnderlyingDatastores) - 3);
            else
                if isempty(ii)
                    if ~dsIsEmpty
                        fprintf("%s}\n", class(ds.UnderlyingDatastores{1}));
                    end
                else
                    fprintf("%s}\n", class(ds.UnderlyingDatastores{ii+1}));
                end
            end
            matlab.mixin.CustomDisplay.displayPropertyGroups(ds, group);
            disp(getFooter(ds));
        end

        function tf = write(ds, data, writeInfo, outputFmt, varargin)
            tf = false;

            if ~any(contains(ds.SupportedOutputFormats, outputFmt))
                for ii = 1 : numel(ds.UnderlyingDatastores)
                    tf = ds.UnderlyingDatastores{ii}.write(data, writeInfo, outputFmt, varargin{:});
                    if tf
                        break;
                    end
                end
            else
                tf = ds.Writer.write(data, writeInfo, outputFmt, varargin{:});
            end

            if ~tf
                noFilesWrittenMsgID = "MATLAB:datastoreio:combineddatastore:NoFilesWritten";
                error(message(noFilesWrittenMsgID, outputFmt));
            end
        end
    end

    methods(Static)
        function obj = loadobj(s)
            obj = matlab.io.datastore.TransformedDatastore();
            obj.Transforms = s.Transforms;
            obj.IncludeInfo = s.IncludeInfo;
            if isfield(s, "UnderlyingDatastores")
                obj.UnderlyingDatastores = s.UnderlyingDatastores;
            elseif isfield(s, "UnderlyingDatastore")
                obj.UnderlyingDatastores = {s.UnderlyingDatastore};
            else
                obj.UnderlyingDatastores = {};
            end
            if contains(fieldnames(s),"SupportedOutputFormats")
                obj.SupportedOutputFormats = s.SupportedOutputFormats;
            end
        end
    end

    methods (Hidden)
        function frac = progress(ds)
        %PROGRESS   Percentage of consumed data between 0.0 and 1.0
        %
        %   Return a fraction between 0.0 and 1.0 indicating progress as a
        %   double.
        %
        %   Returns the result of calling the PROGRESS method on the
        %   underlying datastores.
        %
        %   See also read, hasdata, reset, readall, preview

            if isempty(ds.UnderlyingDatastores)
                % Progress is always 1 if there are no underlying datastores.
                % This helps provide an indicator that it is not valid to call
                % read on an empty TransformedDatastore.
                frac = 1;
            elseif numel(ds.UnderlyingDatastores) > 1
                % If any one datastore has reached 100% progress, read is
                % completed. Therefore the maximum progress between all
                % underlying datastores will be a good indicator of the 
                % progress of the TransformedDatastore in general.
                frac = max(cellfun(@progress, ds.UnderlyingDatastores));
            else
                % Call progress on the underlying datastore.
                frac = ds.UnderlyingDatastores{1}.progress();
            end
        end

        function tf = isequaln(ds1, ds2, varargin)
        %isequaln   isequaln is overloaded for TransformedDatastore so that
        %   the Transforms property is not included in the comparison.

            % Verify that the object classes are correct
            isObj = @(x) isa(x, "matlab.io.datastore.TransformedDatastore");
            tf = isObj(ds1) && isObj(ds2);

            function x = replaceTransform(x)
                % FunctionObject compares isequaln correctly, even if function_handle
                % does not.
                % Only clear Transforms that are function_handle for the isequaln comparison.
                if isa(x, "function_handle")
                    x = [];
                end
            end

            if tf
                warnState = warning("off","MATLAB:structOnObject");
                c = onCleanup(@() warning(warnState));
                structDs1 = struct(ds1);
                structDs2 = struct(ds2);
                structDs1.Transforms = cellfun(@replaceTransform, structDs1.Transforms, UniformOutput=false);
                structDs2.Transforms = cellfun(@replaceTransform, structDs2.Transforms, UniformOutput=false);
                tf = isequaln(structDs1, structDs2);
            end
        end

        function tf = isRandomizedReadable(ds)
        %isRandomizedReadable    returns true if this datastore is known to
        %   reorder data at random after calling reset or read.
        %
        %   A TransformedDatastore is considered to be reading randomized
        %   data if all the underlying datastores return isRandomizedReadable
        %   true.
        %
        %   See also: isPartitionable, partition, read

            if isempty(ds.UnderlyingDatastores)
                % An empty TransformedDatastore has deterministic behavior 
                % on read (it will always error) and readall (will always
                % return an empty cell array).
                tf = false;
            else
                tf = any(cellfun(@isRandomizedReadable, ds.UnderlyingDatastores));
            end
        end

        function n = numobservations(ds)
        %NUMOBSERVATIONS   the number of observations in this datastore
        %
        %   N = NUMOBSERVATIONS(DS) returns the number of observations in
        %   the current datastore state. 
        %
        %   All integer values between 1 and N are valid indices for the 
        %   SUBSET method.
        %
        %   DS must be a valid datastore that returns isSubsettable true.
        %   N is a non-negative double scalar.
        %   
        %   See also matlab.io.Datastore.isSubsettable,
        %   matlab.io.datastore.mixin.Subsettable.subset

            ds.verifySubsettable("numobservations");

            if isempty(ds.UnderlyingDatastores)
                % There are no observations available in an empty
                % TransformedDatastore.
                n = 0;
            elseif numel(ds.UnderlyingDatastores) > 1
                n = min(cellfun(@numobservations, ds.UnderlyingDatastores));
            else
                n = ds.UnderlyingDatastores{1}.numobservations();
            end
        end

        function result = visitUnderlyingDatastores(ds, visitFcn, combineFcn)
        %visitUnderlyingDatastores   Overload for TransformedDatastore.
        %
        %   See also: matlab.io.Datastore.visitUnderlyingDatastores

            % Visit TransformedDatastore itself.
            % Performs validation of the function handles too.
            result = ds.visitUnderlyingDatastores@matlab.io.Datastore(visitFcn, combineFcn);

            % Visit all the UnderlyingDatastores and combine the results together.
            for index = 1:numel(ds.UnderlyingDatastores)
                underlyingDs = ds.UnderlyingDatastores{index};
                underlyingResult = underlyingDs.visitUnderlyingDatastores(visitFcn, combineFcn);

                result = combineFcn(result, underlyingResult);
            end
        end

        function TF = isshuffleable(ds)
            % Maintained for compatibility till clients move to
            % isShuffleable instead.
            TF = ismethod(ds.UnderlyingDatastore,'shuffle');
        end

        function TF = ispartitionable(ds)
            % Maintained for compatibility till clients move to
            % isPartitionable instead.
            TF = ds.isPartitionable();
        end
    end

    methods (Access = private)
        function verifySubsettable(ds, methodName)
            if ~ds.isSubsettable()
                ds.buildInvalidTraitError(methodName, 'isSubsettable', 'subsettable');
            end
        end

        function verifyShuffleable(ds, methodName)
            if ~ds.isShuffleable()
                ds.buildInvalidTraitError(methodName, 'isShuffleable', 'shuffleable');
            end
        end

        function verifyPartitionable(ds, methodName)
            if ~ds.isPartitionable()
                ds.buildInvalidTraitError(methodName, 'isPartitionable', 'partitionable');
            end
        end

        function buildInvalidTraitError(ds, invalidMethodName, traitMethodName, traitDescription)
            msgid = "MATLAB:datastoreio:transformeddatastore:invalidTraitValue";
            error(message(msgid, invalidMethodName, class(ds.UnderlyingDatastores), traitDescription, traitMethodName));
        end
    end
end

function dsnew = iConstructWithNewUnderlyingDatastore(newUnderlying,ds)
    dsnew = matlab.io.datastore.TransformedDatastore();
    dsnew.Transforms = ds.Transforms;
    dsnew.IncludeInfo = ds.IncludeInfo;
    dsnew.UnderlyingDatastores = newUnderlying;
end
