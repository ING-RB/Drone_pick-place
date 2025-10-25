function arrds = arrayDatastore(data, varargin)
%arrayDatastore   Generate a datastore that iterates over arrays.
%
%   ARRDS = arrayDatastore(A) creates a datastore ARRDS that iterates through
%       rows of the input array A.
%
%       Executing the READ function on ARRDS will return a part of the data
%       from the input array. For 2D numeric matrices, each READ function
%       call will return a 1-by-1 cell array containing a row vector from the
%       input data by default:
%
%         A = [1 2 3;
%              4 5 6]  % 2-by-3 numeric matrix
%
%         arrds = arrayDatastore(A);
%         read(arrds); % returns {[1 2 3]}
%
%       The output of the READ function can be customized using the "ReadSize",
%       "IterationDimension", and "OutputType" name-value pairs listed below.
%
%   ARRDS = arrayDatastore(__, IterationDimension=DIM) creates
%       a datastore that iterates through the DIM dimension of the input array A.
%       DIM must be specified as a scalar positive integer value.
%
%       If not specified, the IterationDimension is set to 1 by default.
%
%           A = [1 2 3;
%                4 5 6]  % 2-by-3 numeric matrix
%
%           rowds = arrayDatastore(A, IterationDimension=1);
%           rowdata = read(rowds); % Returns the first row from A: {[1 2 3]}
%           rowdata = read(rowds); % Returns the next  row from A: {[4 5 6]}
%           numrows = numpartitions(rowds); % Returns the total number of rows: 2
%
%           colds = arrayDatastore(A, IterationDimension=2);
%           coldata = read(colds); % Returns the first column from A:{[1;
%                                                                      4]}
%           coldata = read(colds); % Returns the next column from A: {[2;
%                                                                      5]}
%           coldata = read(colds); % Returns the next column from A: {[3;
%                                                                      6]}
%           numcols = numpartitions(colds); % Returns the total number of columns: 3
%
%       Setting the IterationDimension property will reset the datastore.
%
%   ARRDS = arrayDatastore(__, OutputType=TYPE) creates a datastore that iterates
%       through an input array and potentially wraps every read in a cell array.
% 
%       TYPE must be specified as a scalar string or a character vector.
%
%       The following two values are currently supported for TYPE:
%
%        - "cell" (default): wraps each block generated from A in a 1-by-1 cell array.
%
%             A = [1 2 3;
%                  4 5 6]
%
%             rowcellds = arrayDatastore(A);
%             read(rowcellds) % Returns the first row in a cell: {[1 2 3]}
%
%        - "same": returns the same datatype as the input array A.
%
%             A = [1 2 3;
%                  4 5 6]
%
%             rowds = arrayDatastore(A);
%             read(rowds) % Returns the first row: [1 2 3]
%
%       Setting the OutputType property will reset the datastore.
%
%   ARRDS = arrayDatastore(__, ReadSize=READSIZE) creates a datastore that reads
%       at most READSIZE blocks from the input array A.
%       READSIZE must be specified as a positive scalar numeric value.
% 
%           A = [1 2;
%                3 4;
%                5 6;
%                7 8;
%                9 0]  % 5-by-2 numeric matrix
%
%           rowds = arrayDatastore(A);
%           read(rowds) % Returns the first row from A: {[1 2]}
%           rowds.ReadSize = 2;
%           read(rowds) % Returns the next two rows from A: {[3 4;
%                                                             5 6]}
%           rowds.ReadSize = 3;
%           read(rowds) % Only two rows left, so READ returns
%                         the last two rows from A: {[7 8;
%                                                     9 0]}
%
%       The "ReadSize" parameter is set to 1 by default.
%
%   matlab.io.datastore.ArrayDatastore Properties:
%
%     IterationDimension - The dimension in which to iterate.
%     ReadSize           - The number of blocks that should be generated on
%                          every call to read.
%     OutputType         - The type of data that is returned by the READ,
%                          READALL, and PREVIEW methods.
%
%   Note: 
%   - Setting the "IterationDimension" or "OutputType" properties will reset
%     the datastore.
%
%   matlab.io.datastore.ArrayDatastore Methods:
%
%     hasdata         - Returns true if there is more data in the datastore.
%     read            - Iterates through the input array and returns the next
%                       block.
%     reset           - Resets the datastore to a state preceding the first
%                       iteration over the array.
%     preview         - Returns the first block of data.
%     readall         - Iterates over the entire input array and vertically
%                       concatenates all the data that was iterated over.
%     partition       - Returns a new datastore that iterates over a part of the
%                       original input array.
%     numpartitions   - Provides an estimate for a reasonable number of
%                       partitions.
%     subset          - Returns a new datastore that contains a subset of the
%                       data in the original datastore.
%     shuffle         - Returns a new datastore that shuffles all the data in
%                       the input datastore.
%     transform       - Create an altered form of the current datastore by
%                       specifying a function handle that will execute
%                       after read on the current datastore.
%     combine         - Create a new datastore that horizontally
%                       concatenates the result of read from two or more
%                       input datastores.
%     isPartitionable - Returns true since ArrayDatastore is always partitionable.
%     isShuffleable   - Returns true since ArrayDatastore is always shuffleable.
%     isSubsettable   - Returns true since ArrayDatastore is always subsettable.
%
%   See also: matlab.io.datastore.ArrayDatastore, matlab.io.datastore.ArrayDatastore.read,
%       matlab.io.Datastore.combine, matlab.io.datastore.ArrayDatastore.readall,
%       matlab.io.datastore.ArrayDatastore.reset

%   Copyright 2020-2022 The MathWorks, Inc.

    try
        arrds = matlab.io.datastore.ArrayDatastore(data, varargin{:});
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
