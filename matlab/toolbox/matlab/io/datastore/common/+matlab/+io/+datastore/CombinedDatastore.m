classdef CombinedDatastore < matlab.io.Datastore ...
        & matlab.mixin.Copyable ...
        & matlab.io.datastore.FileWritable ...
        & matlab.io.datastore.mixin.Subsettable ...
        & matlab.mixin.CustomDisplay

    %CombinedDatastore  A Datastore that conceptually represents the combining
    %   of multiple datastores into a single datastore.
    %
    %   NEWDS = matlab.io.datastore.CombinedDatastore(DS1, DS2, ...) takes a
    %   comma-separated list of datastores, and returns the CombinedDatastore
    %   NEWDS. CombinedDatastore makes a copy of all the input datastores and
    %   resets each of them, storing the result in the UnderlyingDatastores
    %   property. Conceptually, NEWDS is a new datastore instance that is the
    %   horizontally concatenated result of read from each of the underlying
    %   datastores.
    %
    %   CombinedDatastore Methods:
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
    %   shuffle         -    Return a new CombinedDatastore that shuffles
    %                        all the data in the underlying datastores.
    %   partition       -    Return a new CombinedDatastore that contains
    %                        partitioned parts of the original underlying
    %                        datastores.
    %   numpartitions   -    Return an estimate for a reasonable number of
    %                        partitions to use with the partition function.
    %   writeall        -    Writes all the data in the datastore to a new
    %                        output location.
    %
    %   CombinedDatastore Properties:
    %
    %   UnderlyingDatastores     -  The original underlying datastores that
    %                               will be read from. The read of a
    %                               CombinedDatastore is defined by calling
    %                               read on each of the UnderlyingDatastores
    %                               and then horizontally concatenating the
    %                               data from read together.
    %
    %   SupportedOutputFormats   -  List of formats supported for writing
    %                               by this datastore.
    %
    %   See also matlab.io.Datastore.transform, matlab.io.Datastore.combine,
    %   matlab.io.datastore.SequentialDatastore

    %   Copyright 2018-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % UnderlyingDatastores A cell array which contains the datastores
        % which were combined.
        UnderlyingDatastores (1, :) cell;
    end

    properties (Constant)
        SupportedOutputFormats = matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SupportedOutputFormats;
    end

    properties (Constant, Hidden)
        DefaultOutputFormat = string(missing);
    end

    methods
        function ds = CombinedDatastore(varargin)
            %CombinedDatastore   Construct a CombinedDatastore object
            %
            %   DSOUT = CombinedDatastore(ds1, ds2, ...) creates a
            %   CombinedDatastore object containing multiple input datastores.
            %
            %   See also: read, reset, hasdata, combine

            import matlab.io.datastore.internal.validators.validateAndFlattenDatastoreList;
            if nargin > 0
                datastoresIn = validateAndFlattenDatastoreList(varargin, "matlab.io.datastore.CombinedDatastore");
                ds.UnderlyingDatastores = datastoresIn;
                for idx = 1:numel(ds.UnderlyingDatastores)
                    ds.UnderlyingDatastores{idx} = copy(ds.UnderlyingDatastores{idx});
                end

                reset(ds); % Make sure that each of the underlying datastores is reset to beginning
            end
        end

        function data = readall(ds, varargin)

            %READALL   Returns all combined data from the CombinedDatastore
            %
            %   DATA = READALL(CDS) returns all of the horizontally-concatenated
            %   data within this CombinedDatastore.
            %
            %   DATA = READALL(DS, "UseParallel", TF) specifies whether a parallel
            %   pool is used to read all of the data. By default, "UseParallel" is
            %   set to false.
            %
            %   See also read, hasdata, reset, preview

            copyds = copy(ds);
            reset(copyds);

            if ~hasdata(copyds)
                % We can't actually know the number of columns that would
                % result from an empty datastore since we can't call read,
                % so we can't call: cell.empty(0,numCols), since we don't
                % know numCols.
                if nargin > 1
                    matlab.io.datastore.read.validateReadallParameters(varargin{:});
                end
                data = {};
                return
            end
            data = readall@matlab.io.Datastore(copyds, varargin{:});
        end

        function [data, info] = read(ds)
            %READ   Read data and information about the extracted data
            %
            %   DATA = READ(CDS) returns the horizontal concatentation of
            %   data read from all the underlying datastores in this
            %   CombinedDatastore.
            %
            %   [DATA, INFO] = read(CDS) also returns an N-by-1 cell array
            %   combining the second output of the READ method on all the
            %   underlying datastores.
            %
            %   See also hasdata, reset, readall, preview

            if ~hasdata(ds)
                error(message('MATLAB:datastoreio:splittabledatastore:noMoreData'));
            end

            numDatastores = numel(ds.UnderlyingDatastores);
            data = cell(1, numDatastores);
            info = cell(1, numDatastores);
            for ii = 1:numel(ds.UnderlyingDatastores)
                [data{ii}, info{ii}] = read(ds.UnderlyingDatastores{ii});
                data{ii} = matlab.io.datastore.internal.read.iMakeUniform(data{ii}, ds.UnderlyingDatastores{ii});
            end
            data = horzcat(data{:});
        end

        function reset(ds)
            %RESET   Reset all the underlying datastores to the start of data
            %
            %   See also: hasdata, read

            for ii = 1:numel(ds.UnderlyingDatastores)
                reset(ds.UnderlyingDatastores{ii});
            end
        end

        function tf = hasdata(ds)
            %HASDATA   Returns true if more data is available to read
            %
            %   Return a logical scalar indicating availability of data. This
            %   method should be called before calling read.
            %
            %   This method only returns true if all underlying datastores in
            %   the CombinedDatastore have data available for reading.
            %
            %   See also: reset, read

            % If any of the underlying datastores are out of data, the
            % CombinedDatastore is out of data.
            tf = ~isempty(ds.UnderlyingDatastores) && all(cellfun(@(c) hasdata(c),ds.UnderlyingDatastores));
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
            %       in the "Folders" property.
            %
            %     - "flatten": Files are written directly to the output
            %       location without generating any intermediate folders.
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
            %   See also: matlab.io.datastore.CombinedDatastore
            import matlab.io.datastore.write.*;
            try
                % Validate the location input first.
                location = validateOutputLocation(ds, location);
                ds.OrigFileSep = matlab.io.datastore.internal.write.utility.iFindCorrectFileSep(location);

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

        function tf = isPartitionable(ds)
            %isPartitionable   returns true if this datastore is partitionable
            %
            %   A CombinedDatastore is only partitionable when all of its
            %   underlying datastores are one of the following:
            %    - datastores that provide an implementation of the SUBSET
            %      method,
            %    - TransformedDatastores over datastores that provide an
            %      implementation of a SUBSET method,
            %    - CombinedDatastores where every underlying datastore
            %      provides an implementation of a SUBSET method.
            %
            %   This ensures that the horizontal association of data is
            %   preserved even after partitioning.
            %
            %   See also: isShuffleable, partition, numpartitions, subset

            tf = ds.isSubsettable();
        end

        function tf = isShuffleable(ds)
            %isShuffleable   returns true if this datastore is shuffleable
            %
            %   A CombinedDatastore is only shuffleable when all of its
            %   underlying datastores are one of the following:
            %    - datastores that provide an implementation of the SUBSET
            %      method,
            %    - TransformedDatastores over datastores that provide an
            %      implementation of a SUBSET method,
            %    - CombinedDatastores where every underlying datastore
            %      provides an implementation of a SUBSET method.
            %
            %   This ensures that the horizontal association of data is
            %   preserved even after shuffling.
            %
            %   See also: isPartitionable, shuffle,
            %             matlab.io.datastore.CombinedDatastore/subset

            tf = ds.isSubsettable();
        end

        function shufds = shuffle(ds)
            %SHUFFLE    Return a shuffled version of this CombinedDatastore
            %
            %   NEWDS = SHUFFLE(CDS) returns a randomly shuffled copy of CDS.
            %
            %   A CombinedDatastore is only shuffleable when all of its
            %   underlying datastores are subsettable. The isSubsettable
            %   method indicates whether a datastore is subsettable or not.
            %
            %   See also isShuffleable, matlab.io.datastore.Shuffleable

            ds.verifySubsettable("shuffle");
            shufds = shuffle@matlab.io.datastore.mixin.Subsettable(ds);
        end

        function partds = partition(ds, n, index)
            %PARTITION   Return a CombinedDatastore containing a part of the
            %   underlying datastore.
            %
            %   SUBDS = PARTITION(CDS, N, INDEX) partitions CDS into
            %   N parts and returns the partitioned Datastore, SUBDS,
            %   corresponding to INDEX. An estimate for a reasonable
            %   value for N can be obtained by using the NUMPARTITIONS
            %   function.
            %
            %   A CombinedDatastore is only partitionable when all of its
            %   underlying datastores are partitionable. The isPartitionable
            %   method indicates whether a datastore is partitionable or not.
            %
            %   See also: isPartitionable, numpartitions

            ds.verifySubsettable("partition");
            partds = partition@matlab.io.datastore.mixin.Subsettable(ds, n, index);
        end

        function tf = isSubsettable(ds)
            %isSubsettable    returns true if this datastore is subsettable
            %
            %   All underlying datastores must be subsettable in order for a
            %   CombinedDatastore to be subsettable.
            %
            %   See also: isPartitionable, subset

            tf = all(cellfun(@isSubsettable, ds.UnderlyingDatastores));
        end

        function subds = subset(ds, indices)
            %SUBSET   returns a new CombinedDatastore containing the
            %   specified observation indices
            %
            %   SUBDS = SUBSET(DS, INDICES) creates a deep copy of the input
            %   datastore DS containing observations corresponding to INDICES.
            %
            %   It is only valid to call the SUBSET method on a
            %   CombinedDatastore if it returns isSubsettable true.
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
            %       matlab.io.datastore.ImageDatastore.subset

            ds.verifySubsettable("subset");

            import matlab.io.datastore.internal.validators.validateSubsetIndices;

            try
                indices = validateSubsetIndices(indices, ds.numobservations(), ...
                    'CombinedDatastore');
            catch ME
                % Provide a more accurate error message in the empty subset case.
                if ME.identifier == "MATLAB:datastoreio:splittabledatastore:zeroSubset"
                    msgid = "MATLAB:datastoreio:combineddatastore:zeroSubset";
                    error(message(msgid, "CombinedDatastore"));
                end
                throw(ME)
            end

            % Forward to the underlying datastore's subset methods
            fcn = @(ds) ds.subset(indices);
            subds = cellfun(fcn, ds.UnderlyingDatastores, "UniformOutput", false);
            subds = matlab.io.datastore.CombinedDatastore(subds{:});
        end
    end

    methods (Hidden)
        function frac = progress(ds)
            %PROGRESS   Percentage of consumed data between 0.0 and 1.0
            %
            %   Return a fraction between 0.0 and 1.0 indicating progress as a
            %   double.
            %
            %   The progress of a CombinedDatastore is equal to the maximum
            %   progress amongst all the underlying datastores.
            %
            %   See also read, hasdata, reset, readall, preview

            if ~hasdata(ds)
                % Progress is always 1 if there are no underlying datastores.
                % This helps provide an indicator that it is not valid to call
                % read on an empty CombinedDatastore.
                frac = 1;
            else
                % If any one datastore has reached 100% progress, read is
                % completed. Therefore the maximum progress between all
                % underlying datastores will be a good indicator of the
                % progress of the CombinedDatastore in general.
                frac = max(cellfun(@progress, ds.UnderlyingDatastores));
            end
        end

        function s = saveobj(ds)
            s.UnderlyingDatastores = ds.UnderlyingDatastores;
            s.SupportedOutputFormats = ds.SupportedOutputFormats;
        end

        function tf = isRandomizedReadable(ds)
            %isRandomizedReadable    returns true if this datastore is known to
            %   reorder data at random after calling reset or read.
            %
            %   A CombinedDatastore is considered to be reading randomized
            %   data if any underlying datastore returns isRandomizedReadable
            %   true.
            %
            %   See also: isPartitionable, partition, read

            % Check if any underlying datastores are RandomizedReadable or not.
            tf = any(cellfun(@isRandomizedReadable, ds.UnderlyingDatastores));
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
            % Handle the empty case first.
            if isempty(ds.UnderlyingDatastores)
                n = 0;
            else
                n = min(cellfun(@numobservations, ds.UnderlyingDatastores));
            end
        end

        function result = visitUnderlyingDatastores(ds, visitFcn, combineFcn)
            %visitUnderlyingDatastores   Overload for CombinedDatastore.
            %
            %   See also: matlab.io.Datastore.visitUnderlyingDatastores

            % Visit CombinedDatastore itself.
            % Performs validation of the function handles too.
            result = ds.visitUnderlyingDatastores@matlab.io.Datastore(visitFcn, combineFcn);

            % Visit all the UnderlyingDatastores and combine the results together.
            for index = 1:numel(ds.UnderlyingDatastores)
                underlyingDs = ds.UnderlyingDatastores{index};
                underlyingResult = underlyingDs.visitUnderlyingDatastores(visitFcn, combineFcn);

                result = combineFcn(result, underlyingResult);
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
                if isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.CombinedDatastore") || ...
                        isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.TransformedDatastore") || ...
                        isa(ds.UnderlyingDatastores{idx}, "matlab.io.datastore.SequentialDatastore")
                    outFmts = [outFmts, getUnderlyingSupportedOutputFormats(ds.UnderlyingDatastores{idx})]; %#ok<AGROW>
                else
                    outFmts = [outFmts, ds.UnderlyingDatastores{idx}.SupportedOutputFormats]; %#ok<AGROW>
                end
            end
            outFmts = unique(outFmts);
        end
    end

    methods (Access = 'protected')
        function cpObj = copyElement(ds)
            cpObj = copyElement@matlab.mixin.Copyable(ds);

            % Deep copy each of the underlying datastores
            for idx = 1:numel(ds.UnderlyingDatastores)
                ds.UnderlyingDatastores{idx} = copy(ds.UnderlyingDatastores{idx});
            end
        end

        function n = maxpartitions(ds)
            %MAXPARTITIONS Return the maximum number of partitions
            %   possible for the datastore.

            ds.verifySubsettable("numpartitions");
            n = ds.numobservations();
        end

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

        function displayScalarObject(ds)
            % header
            disp(getHeader(ds));
            group = getPropertyGroups(ds);
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
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            obj = matlab.io.datastore.CombinedDatastore();
            obj.UnderlyingDatastores = s.UnderlyingDatastores;
            if contains(fieldnames(s),"SupportedOutputFormats")
                obj.SupportedOutputFormats = s.SupportedOutputFormats;
            end
        end
    end

    methods (Access = private)
        function verifySubsettable(ds, methodName)
            if ~ds.isSubsettable()
                ds.buildInvalidTraitError(methodName, 'isSubsettable', 'subsettable');
            end
        end

        function buildInvalidTraitError(ds, invalidMethodName, traitMethodName, traitDescription)
            traitTable = ds.buildTraitTable();

            % Render the table display into a string.
            fh = feature('hotlinks');
            if fh
                traitsDisp = evalc('disp(traitTable);');
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                traitsDisp = evalc('feature hotlinks off; disp(traitTable);');
                feature('hotlinks', fh);
            end

            msgid = "MATLAB:datastoreio:combineddatastore:invalidTraitValue";
            msg = message(msgid, invalidMethodName, "CombinedDatastore", traitDescription, traitsDisp, traitMethodName);
            throwAsCaller(MException(msg));
        end

        function t = buildTraitTable(ds)
            % Assemble the metadata for the required table.
            traits = ["isPartitionable", "isShuffleable", "isSubsettable"];
            variableNames = ["Index", "Underlying datastore class", traits];
            variableTypes = ["double", "string", "string", "string", "string"];

            % Pre-allocate the table
            t = table('Size', [numel(ds.UnderlyingDatastores), numel(variableNames)], ...
                'VariableTypes', variableTypes, ...
                'VariableNames', variableNames);

            % Populate each row of the table.
            for index = 1:numel(ds.UnderlyingDatastores)
                underlyingDatastore = ds.UnderlyingDatastores{index};
                t{index, 1} = index;
                t{index, 2} = string(class(underlyingDatastore));
                t{index, 3} = underlyingDatastore.isPartitionable();
                t{index, 4} = underlyingDatastore.isShuffleable();
                t{index, 5} = underlyingDatastore.isSubsettable();
            end
        end
    end
end