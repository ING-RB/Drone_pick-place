classdef SequentialDatastore < matlab.io.Datastore ...
        & matlab.mixin.Copyable ...
        & matlab.io.datastore.mixin.Subsettable ...
        & matlab.io.datastore.FileWritable ...
        & matlab.mixin.CustomDisplay

    %SequentialDatastore  A Datastore that conceptually represents
    %   the combining of multiple datastores into a single datastore that
    %   reads from the underlying datastores, sequentially.
    %
    %   NEWDS = combine(DS1, DS2, ..., READORDER="SEQUENTIAL") takes a
    %   comma-separated list of datastores, and returns the SequentialDatastore
    %   NEWDS. SequentialDatastore makes a copy of all the input datastores and
    %   resets each of them, storing the result in the UnderlyingDatastores
    %   property. A SequentialDatastore is a single datastore whose number of
    %   reads is the sum of the number of reads of the underlying datastores.
    %
    %   Note: the combine name-value argument READORDER is specified as either
    %   "associated" (default) to return a CombinedDatastore or "sequential"
    %   to return a SequentialDatastore.
    %
    %   SequentialDatastore Methods:
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
    %   shuffle         -    Return a new SequentialDatastore that
    %                        shuffles all the data in the underlying datastores.
    %   partition       -    Return a new SequentialDatastore that
    %                        contains partitioned parts of the original
    %                        underlying datastores.
    %   numpartitions   -    Return an estimate for a reasonable number of
    %                        partitions to use with the partition function.
    %   subset          -    Subsets the SequentialDatastore
    %                        according to the specified file indices.
    %   writeall        -    Writes all the data in the datastore to a new
    %                        output location.
    %
    %   SequentialDatastore Properties:
    %
    %   UnderlyingDatastores     -  The original underlying datastores that
    %                               will be read from.
    %
    %   SupportedOutputFormats   -  List of formats supported for writing
    %                               by this datastore.
    %
    %   See also matlab.io.Datastore.transform, matlab.io.Datastore.combine,
    %   matlab.io.datastore.CombinedDatastore

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % UnderlyingDatastores A cell array which contains the datastores
        % which were combined.
        UnderlyingDatastores (:, 1) cell;
    end

    properties (Access = private)
        CurrentDatastoreIndex;

        % Set only when partitioning by "Files".
        isFilesPartitionable;
    end

    properties (Constant)
        SupportedOutputFormats = matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SupportedOutputFormats;
    end

    properties (Constant, Hidden)
        DefaultOutputFormat = string(missing);
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of SequentialDatastore in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods
        function ds = SequentialDatastore(varargin)
            %SequentialDatastore   Construct a
            %   SequentialDatastore object
            %
            %   DSOUT = SequentialDatastore(ds1, ds2, ...) creates
            %   a SequentialDatastore object containing multiple
            %   input datastores.
            %
            %   See also: read, reset, hasdata, combine

            import matlab.io.datastore.internal.validators.validateAndFlattenDatastoreList;
            if nargin > 0
                datastoresIn = validateAndFlattenDatastoreList(varargin, "matlab.io.datastore.SequentialDatastore");
                ds.UnderlyingDatastores = datastoresIn;
                for idx = 1:numel(ds.UnderlyingDatastores)
                    ds.UnderlyingDatastores{idx} = copy(ds.UnderlyingDatastores{idx});
                end
            end

            reset(ds); % Reset all underlying datastores as well as empty datastore at construction.
        end
    end

    methods (Hidden)
        frac = progress(ds);

        s = saveobj(ds);

        tf = isRandomizedReadable(ds);

        n = numobservations(ds);

        result = visitUnderlyingDatastores(ds, visitFcn, combineFcn);
    end

    methods (Access = {?matlab.io.datastore.FileWritable, ...
            ?matlab.bigdata.internal.executor.FullfileDatastorePartitionStrategy})
        [files, numFilesPerDS] = getFiles(ds);

        outFmts = getUnderlyingSupportedOutputFormats(ds);
    end

    methods (Access = 'protected')
        cpObj = copyElement(ds);

        n = maxpartitions(ds);

        folders = getFolders(ds);

        filename = getCurrentFilename(~, info);

        tf = write(ds, data, writeInfo, outputFmt, varargin);

        tf = currentFileIndexComparator(ds, currFileIndex);

        displayScalarObject(ds)
    end

    methods (Static, Hidden)
        obj = loadobj(s);
    end
end