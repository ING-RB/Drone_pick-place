classdef (AllowedSubclasses = {?matlab.io.datastore.SplittableDatastore, ...
                               ?matlab.io.datastore.DatabaseDatastore, ...
                               ?matlab.io.datastore.AbstractDatastoreTestBase, ...
                               ?matlab.io.datastore.TabularDatastore}) ...
        Datastore < handle ...
                  & matlab.io.datastore.internal.DatastoreTraits
%Datastore   Declares the interface expected of datastores.
%   This class captures the interface expected of datastores. Datastores
%   are a way to access collections of data via iteration.
%   
%   See also datastore, matlab.io.datastore.SplittableDatastore

%   Copyright 2014-2022 The MathWorks, Inc.

    %
    % Datastores that want to support auto-selection of their class through
    % the datastore gateway function, should define the following method.
    %
    % methods (Access = 'public', Static = true, Abstract = true)
    %     %supportsLocation Return true if the location is supported.
    %     %   Returns true if the location can be read by this datastore
    %     %   type, else returns false.
    %     tf = supportsLocation(loc);
    % end
    %

    methods (Access = 'public', Abstract = true)
        %hasdata   Returns true if more data is available.
        %   Return logical scalar indicating availability of data. This
        %   method should be called before calling read.
        tf = hasdata(ds);
        
        %read   Read data and information about the extracted data.
        %   Return the data extracted from the datastore in the appropriate
        %   form for this datastore. Also return information about where
        %   the data was extracted from in the datastore.
        [data, info] = read(ds);
        
        %readall   Attempt to read all data from the datastore.
        %   Returns all the data in the datastore and resets it.
        %   To execute readall in parallel, supply a value of true
        %   to the "UseParallel" parameter.
        data = readall(ds, varargin);
        
        %preview   Preview the data contained in the datastore.
        %   Returns a small amount of data from the start of the datastore.
        data = preview(ds);
        
        %reset   Reset to the start of the data.
        %   Reset the datastore to the state where no data has been read
        %   from it.
        reset(ds);

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

    methods (Access = 'public', Abstract = true, Hidden = true)

        %progress   Percentage of consumed data between 0.0 and 1.0.
        %   Return fraction between 0.0 and 1.0 indicating progress.
        frac = progress(ds);

    end
    
end