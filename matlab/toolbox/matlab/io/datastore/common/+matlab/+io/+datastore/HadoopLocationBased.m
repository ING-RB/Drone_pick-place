classdef HadoopLocationBased < handle
    % HADOOPLOCATIONBASED Declares the interface that adds support for Hadoop to
    % the datastore.
    %   This abstract class is a mixin for subclasses of matlab.io.Datastore
    %   that adds support for Hadoop to the datastore.
    %
    %   HadoopLocationBased Methods:
    %
    %   initializeDatastore   -    Initializes the datastore with necessary
    %                              split information sent from Hadoop.
    %   getLocation           -    Returns the location to which this
    %                              datastore points.
    %   isfullfile            -    Returns a logical indicating whether or not
    %                              initializeDatastore method must get information
    %                              for one complete file. This is only required
    %                              for file-based data.
    %
    %   HadoopLocationBased Method Attributes:
    %
    %   initializeDatastore   -    Access=protected, Abstract
    %   getLocation           -    Access=protected, Abstract
    %   isfullfile            -    Access=protected
    %
    %   The initializeDatastore and getLocation methods must be implemented by
    %   subclasses derived from the HadoopLocationBased class. The isfullfile
    %   method can optionally be implemented for when the datastore represents
    %   file-based data.
    %
    %   Example Implementation:
    %   -----------------------
    %   % Mixing in Hadoop support for the datastore
    %   % This example template builds on the example implementation found in
    %   % matlab.io.Datastore and matlab.io.datastore.Partitionable. All three
    %   % templates are meant to be used in conjunction to get a partitioned
    %   % datastore that can be used in a Hadoop environment.
    %   classdef MyDatastore < matlab.io.Datastore & ...
    %                          matlab.io.datastore.Partitionable & ...
    %                          matlab.io.datastore.HadoopLocationBased
    %       ...
    %       ...
    %       methods (Hidden)
    %           function initializeDatastore(ds, info)
    %               %INITIALIZEDATASTORE Initialize the datastore with necessary
    %               %   split information sent from Hadoop.
    %               %
    %               %   initializeDatastore(DS, INFO) initializes the datastore with
    %               %   necessary information sent from Hadoop. Input argument INFO
    %               %   will be a table with format depending on the output of
    %               %   GETLOCATION:
    %               %     1) If GETLOCATION is file-based, INFO will consist of
    %               %        FileName, Offset and Size. The FileName is of type char
    %               %        and variables Offset and Size is of type double.
    %               %     2) If GETLOCATION is a table, INFO will be
    %               %        exactly one row of the GETLOCATION table.
    %
    %               % This example implementation initializes the datastore based on
    %               % Hadoop split information to store it as a DsFileSet object.
    %               % The property FileSet is of type matlab.io.datastore.DsFileSet.
    %               ds.FileSet = matlab.io.datastore.DsFileSet(info, ...
    %                  'FileSplitSize',ds.FileSet.FileSplitSize);
    %               reset(ds.FileSet);
    %               reset(ds);
    %           end
    %
    %           function location = getLocation(ds)
    %               %GETLOCATION Return the location of the files in Hadoop.
    %               %
    %               %   LOCATION = getLocation(DS) returns the location of the files
    %               %   in Hadoop to which this datastore points. Output argument
    %               %   LOCATION can be either a:
    %               %     1) list of files or directories as a string array or cell
    %               %        array of characters.
    %               %     2) object of type matlab.io.datastore.DsFileSet.
    %               %     3) table with variable Hostname.
    %
    %               % This example implementation returns the FileSet property
    %               % of the datastore. The property FileSet is of type
    %               % matlab.io.datastore.DsFileSet.
    %               location = ds.FileSet;
    %           end
    %
    %           function tf = isfullfile(ds)
    %               %ISFULLFILE Return whether datastore supports full file or not.
    %               %
    %               %   TF = isfullfile(DS) returns a logical indicating whether or not
    %               %   initializeDatastore method must get information for one complete file.
    %               %   This is only used for file-based output of GETLOCATION.
    %
    %               % This example implementation checks if the FileSplitSize property of
    %               % DsFileSet is 'file' or not. The property FileSet is a
    %               % matlab.io.datastore.DsFileSet object.
    %               tf = isequal(ds.FileSet.FileSplitSize, 'file');
    %           end
    %       end
    %   end
    %
    %   Example usage:
    %   -------------
    %   % Construct a datastore with data from a Hadoop server
    %   setenv('HADOOP_HOME', '/path/to/hadoop/install');
    %   ds = MyDatastore('hdfs://myhadoopserver:8088/mydatafiles',2);
    %   % while there is more data available in the datastore, read from the datastore
    %   while hasdata(ds)
    %       [data, info] = read(ds);
    %   end
    %
    %   % Use tall arrays on Spark with parallel cluster configuration.
    %   % Refer to the documentation on how to,
    %   % "Use tall arrays on a Spark Enabled Hadoop Cluster".
    %   t = tall(ds);
    %
    %   % Gather the head of the tall array
    %   hd = gather(head(t));
    %
    %   See also tall, matlab.io.Datastore, matlab.io.datastore.Partitionable,
    %   matlab.io.datastore.DsFileSet.
    
    %   Copyright 2018 The MathWorks, Inc.
    
    methods (Access = protected, Abstract)
        %INITIALIZEDATASTORE Initialize the datastore with necessary
        %   split information sent from Hadoop.
        %
        %   initializeDatastore(DS, INFO) initializes the datastore with
        %   necessary information sent from Hadoop. Input argument INFO
        %   will be a table with format depending on the output of
        %   GETLOCATION:
        %     1) If GETLOCATION is file-based, INFO will consist of
        %        FileName, Offset and Size. The FileName is of type char
        %        and variables Offset and Size is of type double.
        %     2) If GETLOCATION is a table, INFO will be
        %        exactly one row of the GETLOCATION table.
        %
        %   This is an abstract method and must be implemented by
        %   the subclasses.
        %
        %   Here is an example using DsFileSet:
        %
        %   function initializeDatastore(ds, hadoopInfo)
        %       % The property FileSet is a matlab.io.datastore.DsFileSet object.
        %       ds.FileSet = matlab.io.datastore.DsFileSet(hadoopInfo);
        %       reset(ds.FileSet);
        %       reset(ds);
        %   end
        %
        %   See also matlab.io.Datastore, isfullfile, getLocation,
        %            matlab.io.datastore.Partitionable,
        %            matlab.io.datastore.DsFileSet.
        initializeDatastore(ds, info);
        
        %GETLOCATION Return the location of the files in Hadoop.
        %
        %   LOCATION = getLocation(DS) returns the location of the files
        %   in Hadoop to which this datastore points. Output argument
        %   LOCATION can be either a:
        %     1) list of files or directories as a string array or cell
        %        array of characters.
        %     2) object of type matlab.io.datastore.DsFileSet.
        %     3) table with variable Hostname.
        %
        %   Both a list of files or directories and DsFileSet represent
        %   file-based partitioning. Hadoop will choose a partitioning
        %   based on how the files are stored in HDFS.
        %
        %   A table represents more general based partitioning schemes.
        %   Hadoop will use the provided list of hostnames to choose the
        %   partitioning.
        %
        %   This is an abstract method and must be implemented by
        %   the subclasses.
        %
        %   Here is an example using DsFileSet:
        %
        %   function location = getLocation(ds)
        %       % The property FileSet is a matlab.io.datastore.DsFileSet object.
        %       location = ds.FileSet;
        %   end
        %
        %   See also matlab.io.Datastore, isfullfile, initializeDatastore,
        %            matlab.io.datastore.Partitionable,
        %            matlab.io.datastore.DsFileSet.
        location = getLocation(ds);
    end
    
    methods (Access = protected)
        function tf = isfullfile(~)
            %ISFULLFILE Return whether datastore supports full file or not.
            %
            %   TF = isfullfile(DS) returns a logical indicating whether or not
            %   initializeDatastore method must get information for one complete file.
            %   This is only used for file-based output of GETLOCATION.
            %
            %   In a Hadoop environment it is typically inefficient to work over
            %   full files. Whenever it is possible to read chunks of files
            %   this function should return false.
            %
            %   Here is an example using DsFileSet:
            %
            %   function tf = isfullfile(ds)
            %       % The property FileSet is a matlab.io.datastore.DsFileSet object.
            %       tf = isequal(ds.FileSet.FileSplitSize, 'file');
            %   end
            %
            %   See also matlab.io.Datastore, getLocation, initializeDatastore,
            %            matlab.io.datastore.Partitionable,
            %            matlab.io.datastore.DsFileSet.
            tf = false;
        end
    end
    
    methods (Access = {?matlab.io.datastore.internal.shim, ?matlab.io.datastore.internal.FrameworkDatastore})
        function internalInitializeDatastore(ds, info)
            initializeDatastore(ds,info);
        end
        function location = internalGetLocation(ds)
            location = getLocation(ds);
        end
        function tf = internalIsFullfile(ds)
            tf = isfullfile(ds);
        end
    end
end
