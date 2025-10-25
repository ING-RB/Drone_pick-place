classdef RangeDatastore < matlab.io.Datastore ...
                        & matlab.io.datastore.Partitionable
%matlab.io.datastore.internal.RangeDatastore   A datastore that iterates over a range of numbers.
%
%   RDS = matlab.io.datastore.internal.RangeDatastore(End=N) creates a datastore RDS
%       that iterates from 1 to N with a step of 1.
%
%         rds = matlab.io.datastore.internal.RangeDatastore(End=3);
%         hasdata(rds); % true
%
%         read(rds);    % 1
%         read(rds);    % 2
%         read(rds);    % 3
%         hasdata(rds); % false
%
%       N must be a non-negative integral numeric value.
%       If N is 0, then hasdata will always return false.
%       When not specified, N defaults to 0.
%
%   RDS = matlab.io.datastore.internal.RangeDatastore(__, ReadSize=SZ) creates
%       a datastore that iterates from 1 to N while returning at most SZ values
%       on each call to read().
%
%         rds = matlab.io.datastore.internal.RangeDatastore(Start=1, End=3, ReadSize=2);
%         hasdata(rds); % true
%
%         read(rds);    % [1; 2]
%         read(rds);    % 3
%         hasdata(rds); % false
%
%       SZ must be specified as a positive finite integral numeric value.
%       SZ defaults to 1 when not specified.
%       Note: the last read() call may return less than SZ values if N is not
%             an exact multiple of SZ.
%
%   RDS = matlab.io.datastore.internal.RangeDatastore(__, Start=ST) creates
%       a datastore that starts iteration from ST.
%
%         rds = matlab.io.datastore.internal.RangeDatastore(Start=2, End=4);
%         hasdata(rds); % true
%
%         read(rds);    % 2
%         read(rds);    % 3
%         read(rds);    % 4
%         hasdata(rds); % false
%
%       ST must be specified as a non-negative finite integral numeric value.
%       ST defaults to 1 if not specified.
%
%   matlab.io.datastore.internal.RangeDatastore Properties:
%
%     Start          | Iteration start value                 | uint64 | Read-only
%     End            | Iteration end value                   | uint64 | Read-only
%     ReadSize       | Number of values returned during read | uint64 | Settable
%     NumValuesRead  | Number of values read                 | uint64 | Read-only
%     TotalNumValues | Total number of values to be read     | uint64 | Read-only
%
%   matlab.io.datastore.internal.RangeDatastore Methods:
%
%     hasdata       - Returns true if there is more data in the datastore.
%     read          - Returns the next value in the range.
%     reset         - Resets the datastore to the start of the range.
%     preview       - Returns the first 8 values in the range.
%     readall       - Returns the entire range of data.
%     partition     - Returns a new datastore that iterates over a part of the
%                     original range.
%     numpartitions - Provides an estimate for a reasonable number of
%                     partitions.
%     transform     - Create an altered form of the current datastore by
%                     specifying a function handle that will execute
%                     after read on the current datastore.
%     combine       - Create a new datastore that horizontally
%                     concatenates the result of read from two or more
%                     input datastores.
%
%   See also: arrayDatastore, matlab.io.datastore.ArrayDatastore.read,
%       matlab.io.Datastore.combine, matlab.io.datastore.ArrayDatastore.readall,
%       matlab.io.datastore.ArrayDatastore.reset

%   Copyright 2021 The MathWorks, Inc.

    % Developer's Notes:
    % - This datastore is not subsettable since it is built around the idea of
    %   having a contiguous range of values. It is not clear what shuffle() or
    %   subset() with non-contigugous indices would mean in RangeDatastore.
    %   You probably want ArrayDatastore instead if you need subset() with RangeDatastore.
    % - This datastore does not customize copyElement or isequal/isequaln. But if you're
    %   composing this datastore, you will need to override copyElement, and maybe
    %   override isequal/isequaln (and probably saveobj/loadobj) too.

    properties (SetAccess = private)
        %Start - Value to start iteration at.
        %
        %   RangeDatastore will return values between Start and End inclusive.
        %
        %   The default value for Start is 1.
        %
        Start (1, 1) uint64 = 1;

        %End - Last value to return from iteration.
        %
        %   RangeDatastore will return values between Start and End inclusive.
        %
        %   The default value for End is 0. This means that End usually must be
        %   specified to avoid creating an empty RangeDatastore.
        %
        End (1, 1) uint64 = 0;
    end

    properties
        %ReadSize - Amount of data to read.
        %
        %   RangeDatastore will return at most ReadSize values from each read() method call.
        %
        %   ReadSize must be positive. The default value for ReadSize is 1.
        %
        ReadSize (1, 1) uint64 {mustBePositive} = 1;
    end

    properties (SetAccess = private)
        %NumValuesRead   The number of values read so far between Start and End.
        %
        %   After construction and reset(), NumValuesRead will always be 0.
        %   It is incremented on every read thereafter.
        %
        %   After all reads, when hasdata() is false, NumValuesRead will be:
        %     - 0, if the Start and End values correspond to an empty range, or
        %     - (End - Start + 1), if the range is non-empty.
        %
        %   NumValuesRead is a read-only uint64 property.
        %
        NumValuesRead(1, 1) uint64 = 0;
    end

    properties (SetAccess = private, Dependent)
        %TotalNumValues   The total number of values to be read between Start and End.
        %
        %   Will always be 0 for an empty range. Will be End-Start+1 for a non-empty range.
        %
        %   TotalNumValues is a read-only uint64 property.
        %
        TotalNumValues(1, 1) uint64;
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of RangeDatastore in R2022a.
        ClassVersion(1, 1) uint64 = 1;
    end

    methods
        function rds = RangeDatastore(args)
            arguments
                args.Start    (1, 1) uint64 = 1;
                args.End      (1, 1) uint64 = 0;
                args.ReadSize (1, 1) uint64 {mustBePositive} = 1;
            end

            rds.Start    = args.Start;
            rds.End      = args.End;
            rds.ReadSize = args.ReadSize;
        end

        function N = get.TotalNumValues(rds)

            if rds.End >= rds.Start
                N = rds.End - rds.Start + 1;
            else
                % Account for empty ranges.
                N = 0x0u64;
            end
        end
    end

    methods (Access = protected)
        function n = maxpartitions(rds)
            n = double(rds.TotalNumValues);
        end
    end

    % Hide saveobj and loadobj.
    methods (Hidden)
        S = saveobj(rds);
    end

    methods (Hidden, Static)
        rds = loadobj(S);
    end
end
