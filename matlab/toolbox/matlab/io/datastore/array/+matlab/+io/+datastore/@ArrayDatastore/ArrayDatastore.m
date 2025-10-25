classdef ArrayDatastore < matlab.io.Datastore ...
                        & matlab.io.datastore.mixin.Subsettable
%matlab.io.datastore.ArrayDatastore   A datastore that iterates over arrays.
%
%   ARRDS = matlab.io.datastore.ArrayDatastore(A) creates a datastore ARRDS
%       that iterates through rows of the input array A.
%
%       Executing the READ function on ARRDS will return a part of the data
%       from the input array. For 2D numeric matrices, each READ function
%       call will return a 1-by-1 cell array containing a row vector from the
%       input data by default:
%
%         A = [1 2 3;
%              4 5 6]  % 2-by-3 numeric matrix
%
%         arrds = matlab.io.datastore.ArrayDatastore(A);
%         read(arrds); % returns {[1 2 3]}
%
%       The output of the READ function can be customized using the "ReadSize",
%       "IterationDimension", and "OutputType" name-value pairs listed below.
%
%   ARRDS = matlab.io.datastore.ArrayDatastore(__, IterationDimension=DIM) creates
%       a datastore that iterates through the DIM dimension of the input array A.
%       DIM must be specified as a scalar positive integer value.
%
%       If not specified, the IterationDimension is set to 1 by default.
%
%           A = [1 2 3;
%                4 5 6]  % 2-by-3 numeric matrix
%
%           rowds = matlab.io.datastore.ArrayDatastore(A, IterationDimension=1);
%           rowdata = read(rowds); % Returns the first row from A: {[1 2 3]}
%           rowdata = read(rowds); % Returns the next  row from A: {[4 5 6]}
%           numrows = numpartitions(rowds); % Returns the total number of rows: 2
%
%           colds = matlab.io.datastore.ArrayDatastore(A, IterationDimension=2);
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
%   ARRDS = matlab.io.datastore.ArrayDatastore(__, OutputType=TYPE) creates
%       a datastore that iterates through an input array and potentially wraps
%       every read in a cell array. TYPE must be specified as a scalar string
%       or a character vector.
%
%       The following two values are currently supported for TYPE:
%
%        - "cell" (default): wraps each block generated from A in a 1-by-1 cell array.
%
%             A = [1 2 3;
%                  4 5 6]
%
%             rowcellds = matlab.io.datastore.ArrayDatastore(A);
%             read(rowcellds) % Returns the first row in a cell: {[1 2 3]}
%
%        - "same": returns the same datatype as the input array A.
%
%             A = [1 2 3;
%                  4 5 6]
%
%             rowds = matlab.io.datastore.ArrayDatastore(A);
%             read(rowds) % Returns the first row: [1 2 3]
%
%       Setting the OutputType property will reset the datastore.
%
%   ARRDS = matlab.io.datastore.ArrayDatastore(__, ReadSize=READSIZE) creates
%       a datastore that reads at most READSIZE blocks from the input array A.
%       READSIZE must be specified as a positive scalar numeric value.
%
%           A = [1 2;
%                3 4;
%                5 6;
%                7 8;
%                9 0]  % 5-by-2 numeric matrix
%
%           rowds = matlab.io.datastore.ArrayDatastore(A);
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
%   See also: arrayDatastore, matlab.io.datastore.ArrayDatastore.read,
%       matlab.io.Datastore.combine, matlab.io.datastore.ArrayDatastore.readall,
%       matlab.io.datastore.ArrayDatastore.reset

%   Copyright 2020-2022 The MathWorks, Inc.

    properties
        %ReadSize - Amount of data to read.
        %
        %   ArrayDatastore will return at most ReadSize blocks from each read() method call.
        %
        %   The default value for ReadSize is 1.
        %
        ReadSize (1, 1) = 1

        %IterationDimension - Dimension in which to iterate.
        %
        %   Set IterationDimension in order to change the dimension over which ArrayDatastore
        %   will iterate.
        %
        %   The default value for IterationDimension is 1. Therefore ArrayDatastore will iterate
        %   over the rows of the input array by default.
        %
        %   IterationDimension is only configurable when "OutputType" is set to "cell". If
        %   "OutputType" is set to "same", then ArrayDatastore will always iterate over the
        %   rows of the input array.
        %
        IterationDimension (1, 1) = 1

        %OutputType - Type of data returned by the READ, READALL, and PREVIEW methods.
        %
        %   OutputType defaults to "cell", which means that each block of data in the input
        %   array will be wrapped in a 1-by-1 cell before being returned by the READ method.
        %
        %   Change OutputType to "same" in order to preserve the input datatype when reading.
        %   Note that "IterationDimension" is not configurable when OutputType is set to "same".
        %
        OutputType = "cell"
    end

    properties (Hidden)
        %ConcatenationDimension - Concatenate data in a specific dimension during the
        %                         READ, READALL, and PREVIEW methods.
        %
        %   By default, ArrayDatastore will always vertically concatenate data to be
        %   consistent with other datastores (i.e. ConcatenationDimension is set to 1).
        %
        %   However, ConcatenationDimension can be changed to make ArrayDatastore concatenate
        %   data in another dimension. For example, ConcatenationDimension can be set to 4
        %   to ensure that data is concatenated in the fourth dimension during read and readall.
        %
        ConcatenationDimension(1, 1) = 1
    end

    properties (Access = private)
        % Property to store the actual data passed in as input.
        Data = [];

        % The index that tracks the current position of the ArrayDatastore.
        % Incremented on every read.
        NumBlocksRead(1, 1) double {mustBeNonnegative} = 0;
    end

    % ArrayDatastore gets reconstructed on load, so this is recomputed in
    % the constructor.
    properties (Access = private, Transient)
        % Cell array of indices used to index into the Data.
        IndexVector(1, :) cell = cell.empty(1, 0);

        % Fully specified through IterationDimension and Data.
        TotalNumBlocks(1, 1) double {mustBeNonnegative, mustBeInteger};
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ArrayDatastore (R2020b).
        % ClassVersion = 2 adds a cached IndexVector property to improve performance (R2022b).
        ClassVersion(1, 1) double = 2;
    end

    methods
        function arrds = ArrayDatastore(data, varargin)
            try
                nvStruct = parseNVPairs(varargin{:});

                arrds.Data = data;
                arrds.ReadSize = nvStruct.ReadSize;
                arrds.OutputType = nvStruct.OutputType;

                arrds.ConcatenationDimension = nvStruct.ConcatenationDimension;
                arrds.IterationDimension = nvStruct.IterationDimension;
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
        
        function set.ReadSize(arrds, readSize)
            arrds.ReadSize = validateReadSize(readSize);
        end

        function set.OutputType(arrds, outputType)
            arrds.OutputType = validateIterationParameter(arrds, OutputType=outputType);
            arrds.recomputeCachedProperties();
        end

        function set.IterationDimension(arrds, iterationDimension)
            arrds.IterationDimension = validateIterationParameter(arrds, IterationDimension=iterationDimension); %#ok<*MCSUP> 
            arrds.recomputeCachedProperties();
        end

        function set.ConcatenationDimension(arrds, concatenationDimension)
            arrds.ConcatenationDimension = validateIterationParameter(arrds, ConcatenationDimension=concatenationDimension);
            arrds.recomputeCachedProperties();
        end
    end % methods (Public)

    methods (Hidden)
        % Declaration for the numobservations method, to ensure that it is Hidden.
        n = numobservations(arrds);

        % Declaration for the progress method, to ensure that it is Hidden.
        frac = progress(arrds);

        S = saveobj(arrds);
    end % methods (Hidden)

    methods (Hidden, Static)
        arrds = loadobj(S);
    end
end % classdef ArrayDatastore
