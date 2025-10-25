classdef (Abstract) Datastore < matlab.io.datastore.internal.HandleUnwantedHideable ...
        & matlab.mixin.Copyable ...
        & matlab.io.datastore.internal.ScalarBase ...
        & matlab.io.datastore.internal.DatastoreTraits
    %DATASTORE Declares the interface expected of datastores.
    %   This abstract class captures the interface expected of datastores.
    %   Datastores are a way to access collections of data via iteration.
    %   Datastore is a handle class and a subclass of matlab.mixin.Copyable.
    %
    %   Datastore Methods:
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
    %   progress        -    Return fraction between 0.0 and 1.0 indicating
    %                        percentage of consumed data.
    %   isPartitionable -    Returns true if this datastore is partitionable.
    %   isShuffleable   -    Returns true if this datastore is shuffleable.
    %
    %   Datastore Method Attributes:
    %
    %   preview         -   Public
    %   read            -   Public, Abstract
    %   readall         -   Public
    %   hasdata         -   Public, Abstract
    %   reset           -   Public, Abstract
    %   progress        -   Hidden
    %   combine         -   Public
    %   transform       -   Public
    %   isPartitionable -   Public
    %   isShuffleable   -   Public
    %
    %   This class implements the preview, readall, transform, combine,
    %   isPartitionable, and isShuffleable methods. The read, hasdata, and
    %   reset methods have to be implemented by subclasses derived from the
    %   Datastore class. The default implementations for preview and readall
    %   are not optimized for tall array construction. It is recommended to
    %   implement efficient versions of these methods for improved tall array
    %   performance.
    %
    %   Example Implementation:
    %   ----------------------
    %   % Creating a custom datastore by inheriting from matlab.io.Datastore
    %   classdef MyDatastore < matlab.io.Datastore
    %       properties(Access = private)
    %           % This class consists of 2 properties FileSet and CurrentFileIndex
    %           FileSet matlab.io.datastore.FileSet
    %           CurrentFileIndex double
    %      end
    %
    %       methods(Access = public)
    %           function myds = MyDatastore(location)
    %               % The class constructor to set properties of the datastore.
    %               myds.FileSet = matlab.io.datastore.FileSet(location, ...
    %                   'FileExtensions', '.bin', 'FileSplitSize', 8*1024);
    %               myds.CurrentFileIndex = 1;
    %               reset(myds);
    %           end
    %
    %           function tf = hasdata(myds)
    %               %HASDATA   Returns true if more data is available.
    %               %   Return logical scalar indicating availability of data.
    %               %   This method should be called before calling read. This
    %               %   is an abstract method and must be implemented by the
    %               %   subclasses. hasdata is used in conjunction with read to
    %               %   read all the data within the datastore.
    %               tf = hasfile(myds.FileSet);
    %           end
    %
    %           function [data, info] = read(myds)
    %               %READ   Read data and information about the extracted data.
    %               %   Return the data extracted from the datastore in the
    %               %   appropriate form for this datastore. Also return
    %               %   information about where the data was extracted from in
    %               %   the datastore. Both the outputs are required to be
    %               %   returned from the read method, and can be of any type.
    %               %   info is recommended to be a struct with information
    %               %   about the chunk of data read. data represents the
    %               %   underlying class of tall, if tall is created on top of
    %               %   this datastore. This is an abstract method and must be
    %               %   implemented by the subclasses.
    %
    %               % In this example, the read method reads data from the
    %               % datastore using a custom reader function, MyFileReader,
    %               % which takes the resolved filenames as input. CurrentFileIndex
    %               % is updated every time a new file is read.
    %               if ~hasdata(myds)
    %                   error(sprintf('No more data to read.\nUse reset method to reset the datastore to the start of the data. Before calling the read method, check if data is available to read by using the hasdata method.')); %#ok<SPERR>
    %               end
    %
    %               file = nextfile(myds.FileSet);
    %               data = MyFileReader(file);
    %               info.Size = size(data);
    %               info.FileName = file.FileName;
    %               info.Offset = file.Offset;
    %
    %               % Update CurrentFileIndex when nextfile changes
    %               if file.Offset + file.SplitSize >= file.FileSize
    %                   myds.CurrentFileIndex = myds.CurrentFileIndex + 1;
    %               end
    %           end
    %
    %           function reset(myds)
    %               %RESET   Reset to the start of the data.
    %               %   Reset the datastore to the state where no data has been
    %               %   read from it. This is an abstract method and must be
    %               %   implemented by the subclasses.
    %
    %               % In this example, the datastore is reset to point to the
    %               % first file (and first partition) in the datastore.
    %               reset(myds.FileSet);
    %               myds.CurrentFileIndex = 1;
    %           end
    %
    %           function frac = progress(myds)
    %               %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
    %               %   Return fraction between 0.0 and 1.0 indicating progress as a
    %               %   double. The provided example implementation returns the
    %               %   ratio of the index of the current file from FileSet
    %               %   to the number of files in FileSet. A simpler
    %               %   implementation can be used here that returns a 1.0 when all
    %               %   the data has been read from the datastore, and 0.0
    %               %   otherwise.
    %               %
    %               %   See also matlab.io.Datastore, read, hasdata, reset, readall,
    %               %   preview.
    %               frac = (myds.CurrentFileIndex-1)/myds.FileSet.NumFiles;
    %           end
    %       end
    %
    %       methods(Access = protected)
    %           function dsCopy = copyElement(ds)
    %               %COPYELEMENT   Create a deep copy of the datastore
    %               %   Create a deep copy of the datastore. We need to call
    %               %   copy on the datastore's property FileSet, because it is
    %               %   a handle object. Creating a deep copy allows methods
    %               %   such as readall and preview, that call the copy method,
    %               %   to remain stateless.
    %               dsCopy = copyElement@matlab.mixin.Copyable(ds);
    %               dsCopy.FileSet = copy(ds.FileSet);
    %           end
    %       end
    %   end
    %
    %   function data = MyFileReader(fileInfoTbl)
    %   % create a custom reader object for the specified file
    %   reader = matlab.io.datastore.DsFileReader(fileInfoTbl.FileName);
    %
    %   % seek to the offset
    %   seek(reader,fileInfoTbl.Offset,'Origin','start-of-file');
    %
    %   % read fileInfoTbl.Size amount of data
    %   % the data returned from MyFileReader is a uint8 column vector
    %   data = read(reader,fileInfoTbl.SplitSize);
    %   end
    %
    %   See also datastore, mapreduce, matlab.io.datastore.Partitionable, matlab.io.datastore.HadoopFileBased.

    %   Copyright 2017-2022 The MathWorks, Inc.

    methods(Abstract, Access = public)
        %HASDATA   Returns true if more data is available.
        %   Return logical scalar indicating availability of data. This
        %   method should be called before calling read. This is an
        %   abstract method and must be implemented by the subclasses.
        %   hasdata is used in conjunction with read to read all the data
        %   within the datastore. Following is an example usage:
        %
        %   ds = myDatastore(...);
        %   while hasdata(ds)
        %       [data, info] = read(ds);
        %   end
        %
        %   % reset to read from start of the data
        %   reset(ds);
        %   [data, info] = read(ds);
        %
        %   See also matlab.io.Datastore, read, reset, readall, preview,
        %   progress.
        tf = hasdata(ds);

        %RESET   Reset to the start of the data.
        %   Reset the datastore to the state where no data has been
        %   read from it. This is an abstract method and must be
        %   implemented by the subclasses.
        %   In the provided example, the datastore is reset to point to the
        %   first file (and first partition) in the datastore.
        %
        %   See also matlab.io.Datastore, read, hasdata, readall, preview,
        %   progress.
        reset(ds);

        %READ   Read data and information about the extracted data.
        %   Return the data extracted from the datastore in the
        %   appropriate form for this datastore. Also return
        %   information about where the data was extracted from in
        %   the datastore. Both the outputs are required to be
        %   returned from the read method, and can be of any type.
        %   info is recommended to be a struct with information
        %   about the chunk of data read. data represents the
        %   underlying class of tall, if tall is created on top of
        %   this datastore. This is an abstract method and must be
        %   implemented by the subclasses.
        %
        %   See also matlab.io.Datastore, hasdata, reset, readall, preview,
        %   progress.
        [data, info] = read(ds);
    end

    % Default implementation for Datastore %
    methods(Access = public)
        function data = readall(ds, varargin)
            %READALL   Attempt to read all data from the datastore.
            %   Returns all the data in the datastore and resets it.
            %   This is the default implementation for the readall method,
            %   subclasses can implement an efficient version of this method
            %   by preallocating the data variable. Subclasses should also
            %   consider implementing a more efficient version of this
            %   method for improved tall array construction performance.
            %   In the provided default implementation, a copy of the
            %   original datastore is first reset. While hasdata is true,
            %   it calls read on the copied datastore in a loop.
            %   All the data returned from the individual reads should be
            %   vertically concatenatable, and the datatype of the output
            %   should be the same as that of the read method. For
            %   datastores that can be partitioned, readall can be executed
            %   in parallel by supplying a value of true to the
            %   "UseParallel" parameter.
            %
            %   See also matlab.io.Datastore, read, hasdata, reset, preview,
            %   progress.

            if matlab.io.datastore.read.validateReadallParameters(varargin{:})
                data = matlab.io.datastore.read.readallParallel(ds);
                return;
            end
            copyds = copy(ds);
            reset(copyds);
            if hasdata(copyds)
                data = read(copyds);
            else
                data = [];
            end
            while hasdata(copyds)
                data = [data; read(copyds)]; %#ok<AGROW>
            end
        end

        function data = preview(ds)
            %PREVIEW   Preview the data contained in the datastore.
            %   Returns a small amount of data from the start of the datastore.
            %   This is the default implementation of the preview method,
            %   subclasses can implement an efficient version of this method
            %   by returning a smaller subset of the data directly from the
            %   read method. Subclasses should also consider implementing a
            %   more efficient version of this method for improved tall
            %   array construction performance. The datatype of the output
            %   should be the same as that of the read method. In the
            %   provided default implementation, a copy of the datastore is
            %   first reset. The read method is called on this copied
            %   datastore. The first 8 rows in the output from the read
            %   method call are returned as output of the preview method.
            %
            %   See also matlab.io.Datastore, read, hasdata, reset, readall,
            %   progress.
            copyds = copy(ds);
            reset(copyds);
            data = read(copyds);
            otherDims = repmat({':'}, 1, ndims(data) - 1);
            numRows = min(8,size(data,1));
            substr = substruct('()', [{1:numRows}, otherDims]);
            data = subsref(data, substr);
        end
    end

    methods(Hidden)
        %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
        %   Return fraction between 0.0 and 1.0 indicating progress as a
        %   double. The provided example implementation returns the
        %   ratio of the index of the current file from FileSet
        %   to the number of files in FileSet. The default implementation
        %   simply returns 0.0 while the Datastore has data and 1.0 once
        %   the Datastore is out of data.
        %
        %   See also matlab.io.Datastore, read, hasdata, reset, readall,
        %   preview.
        function frac = progress(ds)
            frac = double(~hasdata(ds));
        end
    end

    methods

        function dsnew = transform(varargin)
            %TRANSFORM   Create a new datastore that applies a function to the
            %   data read from all input datastores.
            %
            %   DSNEW = transform(DS, transformFcn) transforms an input
            %   Datastore, DS, given an input function, transformFcn. The
            %   transform function has the syntax:
            %
            %       dataOut = FCN(dataIn);
            %
            %   where FCN is a function that takes the dataIn returned by
            %   read of DS and returns a modified form of that data,
            %   dataOut.
            %
            %   DSNEW = transform(@FCN, DS1, DS2, ..., DSN) creates a new
            %   datastore that returns the output of FCN after being applied to
            %   the reads from DS1, DS2, ... DSN. FCN must have the following
            %   signature:
            %
            %       DSNEW_DATA = FCN(DS1_DATA, DS2_DATA, ..., DSN_DATA);
            %
            %   DSNEW = transform(DS1, DS2, ..., DSN, @FCN) creates a new
            %   datastore that returns the output of FCN after being applied to
            %   the reads from DS1, DS2, ..., DSN. FCN must have the following
            %   signature:
            %
            %       DSNEW_DATA = FCN(DS1_DATA, DS2_DATA, ..., DSN_DATA);
            %
            %   DSNEW = transform(DS,transformFcn,"IncludeInfo",true)
            %   allows a transformFcn to be defined on DS with an
            %   alternative definition of the transform function that
            %   includes the info returned by the read of DS.
            %
            %       [dataOut, infoOut] = fcn(dataIn,infoIn)
            %
            %   where fcn is a function that takes both the dataIn and
            %   infoIn returned by the read of DS and returns dataOut and
            %   infoOut.
            %
            %   DSNEW = transform(transformFcn,DS1,DS2, ...,DSN,"IncludeInfo",true)
            %   allows a transformFcn to be defined on all the datastores with
            %   an alternative definition of the transform function that
            %   includes the info returned by the reads from each datastore.
            %
            %       [dataOut, infoOut] = fcn(DS1_DATA, DS2_DATA, ..., DSN_DATA, ...
            %                               DS1_INFO, DS2_INFO, ..., DSN_INFO)
            %
            %   where fcn is a function that takes the data and info returned
            %   by the read of each datastore and returns dataOut and infoOut.
            %
            %   See also matlab.io.Datastore, read, hasdata, reset, readall,
            %   preview, matlab.io.Datastore.combine.

            dsnew = matlab.io.datastore.internal.buildTransformedDatastore(varargin{:});
        end

        function dsnew = combine(dsList, opts)
            %COMBINE  Create a CombinedDatastore or SequentialDatastore by
            %   combining data from multiple input datastores. Data from
            %   input datastores is determined by the read() method.
            %
            %   dsnew = combine(ds1, ds2, ds3, ..., "ReadOrder", ORDER)
            %   uses the ReadOrder name-value argument to select the output
            %   datastore type. The datastore type is based on the order in
            %   which data is read from the input datastores. Specify ORDER
            %   as one of these values:
            %
            %       - "associated" (default): Creates a CombinedDatastore
            %       instance that is the horizontally concatenated result
            %       of the read from each of the underlying datastores.
            %
            %       - "sequential": Creates a SequentialDatastore instance
            %        that sequentially reads from the underlying datastores
            %        without concatenation.
            %
            %   See also matlab.io.datastore.CombinedDatastore,
            %   matlab.io.datastore.SequentialDatastore, read, hasdata,
            %   reset, readall, preview, transform.

            arguments (Repeating)
                dsList {matlab.io.datastore.internal.validators.mustBeDatastore(dsList, "MATLAB:datastoreio:combineddatastore:invalidInputs")}
            end

            arguments
                opts.ReadOrder (1,1) string = "associated"
            end

            ReadOrder = validatestring(opts.ReadOrder, ["associated", "sequential"], "combine", "ReadOrder");

            switch ReadOrder
                case "sequential"
                    dsnew = matlab.io.datastore.SequentialDatastore(dsList{:});
                case "associated"
                    dsnew = matlab.io.datastore.CombinedDatastore(dsList{:});
            end
        end
    end
end
