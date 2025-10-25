% FrameworkDatastore
% Decorator around a custom implemented datastore that introduces checks
% and error adjustments. These ensure that violations of the datastore
% contract are reported correctly when the custom datastore is being used
% by a framework such as tall array or mapreduce.

%   Copyright 2017-2022 The MathWorks, Inc.

classdef FrameworkDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.Partitionable ...
        & matlab.io.datastore.HadoopLocationBased
    
    properties (SetAccess = immutable)
        % A logical scalar that specifies if the underlying datastore
        % supports partition.
        IsPartitionable;
        
        % A logical scalar that specifies if the underlying datastore
        % supports any form of Hadoop location-based splitting.
        IsHadoopLocationBased;
        
        % Logical scalar that specifies if the underlying datastore
        % supports file-based. Note, if IsHadoopFileBased is true then
        % IsHadoopLocationBased is also true.
        IsHadoopFileBased;
    end
    
    properties (Dependent)
        % A cell array with the variable names to be read from the
        % datastore.
        SelectedVariableNames;

        % A matlab.io.RowFilter object to perform predicate push-down.
        RowFilter;
    end
    
    properties
        % The underlying datastore object.
        Datastore;
    end
    
    properties (GetAccess = private, SetAccess = immutable)   
        % The classname of the underlying datastore object. This is stored
        % so that we can include this in the error if we cannot deserialize
        % a datastore into a MATLAB Worker.
        DatastoreClassname;
    end
    
    properties (Access = private)
        % A flag that is set to false if the underlying datastore failed to
        % deserialize.
        IsDatastoreValid = true;
    end
    
    methods
        function obj = FrameworkDatastore(ds)
            % Construct a FrameworkDatastore decorator around the given
            % datastore object.
            assert(matlab.io.datastore.internal.shim.isV2ApiDatastore(ds), ...
                'Assertion failed: FrameworkDatastore requires a datastore that inherits from matlab.io.Datastore.');
            obj.Datastore = ds;
            obj.DatastoreClassname = class(ds);
            obj.IsPartitionable = matlab.io.datastore.internal.shim.isPartitionable(ds);
            obj.IsHadoopLocationBased = matlab.io.datastore.internal.shim.isHadoopLocationBased(ds);
            obj.IsHadoopFileBased = matlab.io.datastore.internal.shim.isHadoopFileBased(ds);
        end
    end
    
    % Set/Get methods for Dependent property SelectedVariableNames
    methods
        function set.SelectedVariableNames(obj, selectedVariableNames)
            obj.Datastore.SelectedVariableNames = selectedVariableNames;
        end
        
        function selectedVariableNames = get.SelectedVariableNames(obj)
            selectedVariableNames = obj.Datastore.SelectedVariableNames;
        end
    end

    % Set/Get methods for Dependent property RowFilter
    methods
        function set.RowFilter(obj, rowfilter)
            obj.Datastore.RowFilter = rowfilter;
        end
        
        function rowfilter = get.RowFilter(obj)
            rowfilter = obj.Datastore.RowFilter;
        end
    end
    
    % Overrides of matlab.io.Datastore
    methods
        %HASDATA   Returns true if more data is available.
        function tf = hasdata(obj)
            obj.throwIfInvalid();
            try
                tf = hasdata(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'hasdata');
                rethrow(err);
            end
            
            if ~matlab.io.datastore.internal.validators.isNumLogical(tf)
                error(message('MATLAB:datastoreio:datastore:invalidScalarLogicalOutput', ...
                    class(obj), ...
                    mfilename));
            end
            tf = logical(tf);
        end
        
        %READ   Read data and information about the extracted data.
        function varargout = read(obj)
            obj.throwIfInvalid();
            try
                [varargout{1:nargout}] = read(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'read');
                rethrow(err);
            end
        end
        
        %RESET   Reset to the start of the data.
        function reset(obj)
            obj.throwIfInvalid();
            try
                reset(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'reset');
                rethrow(err);
            end
        end
        
        %READALL   Attempt to read all data from the datastore.
        function data = readall(obj)
            obj.throwIfInvalid();
            try
                data = readall(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'readall');
                rethrow(err);
            end
        end
        
        %PREVIEW   Preview the data contained in the datastore.
        function data = preview(obj)
            obj.throwIfInvalid();
            try
                data = preview(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'preview');
                rethrow(err);
            end
        end
        
        %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
        function frac = progress(obj)
            obj.throwIfInvalid();
            try
                frac = progress(obj.Datastore);
            catch err
                obj.throwIfMalformedMethod(err, 'progress');
                rethrow(err);
            end
        end
    end
    
    % Overrides of matlab.mixin.Copyable
    methods (Access = protected)
        function obj = copyElement(obj)
            obj.throwIfInvalid();
            obj = copy(obj.Datastore);
            obj = matlab.io.datastore.internal.FrameworkDatastore(obj);
        end
    end
    
    % Overrides of matlab.io.datastore.Partitionable
    methods
        function subds = partition(obj, varargin)
            obj.throwIfInvalid();
            try
                subds = partition(obj.Datastore, varargin{:});
            catch err
                obj.throwIfMalformedMethod(err, 'partition');
                rethrow(err);
            end
            
            if ~isa(subds, 'matlab.io.Datastore')
                error(message('MATLAB:datastoreio:datastore:invalidPartitionOutput', ...
                    class(obj), ...
                    mfilename));
            end
            subds = matlab.io.datastore.internal.FrameworkDatastore(subds);
        end
    end
    
    % Overrides of matlab.io.datastore.Partitionable
    methods (Access = protected)
        %MAXPARTITIONS Return the maximum number of partitions possible for
        % the datastore.
        function n = maxpartitions(obj)
            obj.throwIfInvalid();
            n = numpartitions(obj.Datastore);
        end
    end
    
    % Overrides of matlab.io.datastore.HadoopFileBased
    methods (Access = protected)
        %INITIALIZEDATASTORE Initialize the datastore with necessary
        function initializeDatastore(obj, info)
            obj.throwIfInvalid();
            try
                internalInitializeDatastore(obj.Datastore, info);
            catch err
                numCalleeFramesToIgnore = 1;
                obj.throwIfMalformedMethod(err, 'initializeDatastore', numCalleeFramesToIgnore);
                rethrow(err);
            end
        end
        
        %GETLOCATION Return the location of the files in Hadoop.
        function location = getLocation(obj)
            obj.throwIfInvalid();
            try
                location = internalGetLocation(obj.Datastore);
            catch err
                numCalleeFramesToIgnore = 1;
                obj.throwIfMalformedMethod(err, 'getLocation', numCalleeFramesToIgnore);
                rethrow(err);
            end
            
            if ~(      matlab.internal.datatypes.isText(location, true) ...
                    || isa(location, "matlab.io.datastore.DsFileSet") ...
                    || isa(location, "matlab.io.datastore.FileSet") ...
                    || (istable(location) && any(location.Properties.VariableNames == "Hostname")) ...
                    || isa(location, "matlab.io.datastore.HadoopInput") ...
                    )
                error(message('MATLAB:datastoreio:datastore:invalidLocationOutput', ...
                    obj.DatastoreClassname, ...
                    'getLocation'));
            end
        end
        
        %ISFULLFILE Return whether datastore supports full file or not.
        function tf = isfullfile(obj)
            obj.throwIfInvalid();
            try
                tf = internalIsFullfile(obj.Datastore);
            catch err
                numCalleeFramesToIgnore = 1;
                obj.throwIfMalformedMethod(err, 'isfullfile', numCalleeFramesToIgnore);
                rethrow(err);
            end
            
            if ~matlab.io.datastore.internal.validators.isNumLogical(tf)
                error(message('MATLAB:datastoreio:datastore:invalidScalarLogicalOutput', ...
                    class(obj), ...
                    'isfullfile'));
            end
            tf = logical(tf);
        end
    end
    
    methods (Static)
        function obj = loadobj(obj)
            % Custom loadobj implementation that checks whether the
            % underlying datastore object has been corrected loaded. This
            % will be false when the class file for the object doesn't
            % exist on a MATLAB Worker.
            obj.IsDatastoreValid = isa(obj.Datastore, 'matlab.io.Datastore');
        end
    end
    
    methods (Access = private)
        function throwIfInvalid(obj)
            % Throw if the underlying datastore object is invalid.
            if ~obj.IsDatastoreValid
                clzParts = strsplit(obj.DatastoreClassname, '.');
                filename = [clzParts{end}, '.m'];
                err = MException(message('MATLAB:datastoreio:datastore:invalidDatastoreClassOnWorker', ...
                    obj.DatastoreClassname, filename));
                throwAsCaller(err);
            end
        end
        
        function throwIfMalformedMethod(obj, err, methodName, numCalleeFramesToIgnore)
            % Throw if the stack has no frames from the underlying
            % datastore object. If this object is calling a datastore
            % method indirectly (e.g. internalGetLocation -> getLocation),
            % that method can specify a number of stack frames to ignore.
            if nargin < 4
                numCalleeFramesToIgnore = 0;
            end
            
            if numel(err.stack) <= numCalleeFramesToIgnore ...
                    || isequal(err.stack(numCalleeFramesToIgnore + 1).file, [mfilename("fullpath"), '.m'])
                err = MException(message('MATLAB:datastoreio:datastore:malformedDatastoreMethod', ...
                    obj.DatastoreClassname, ...
                    methodName, ...
                    err.message));
                throwAsCaller(err);
            end
        end
    end
end
