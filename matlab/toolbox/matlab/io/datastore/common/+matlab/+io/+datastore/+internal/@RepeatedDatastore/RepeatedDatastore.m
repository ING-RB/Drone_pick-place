classdef RepeatedDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.mixin.Subsettable
%matlab.io.datastore.internal.RepeatedDatastore   Repeat reads from another datastore
%
%   RPTDS = matlab.io.datastore.internal.RepeatedDatastore(DS, REPEATFCN)
%       creates a datastore RPTDS that repeats every read from DS according
%       to the number returned by REPEATFCN.
%
%       DS must be a datastore (subclasss of matlab.io.Datastore or
%       matlab.io.datastore.Datastore).
%
%       REPEATFCN must have the following signature:
%
%           N = REPEATFCN(data)
%
%       where "data" is from each read of DS. N must be a scalar integer
%       value greater than or equal to 0.
%
%       Each read() call from RepeatedDatastore will return the corresponding
%       data from the underlying datastore. Additionally, the info struct
%       returned contains a "RepetitionIndex" value that describes which
%       repetition was returned.
%
%       Here is an example of a datastore that reads spreadsheet files
%       one sheet at a time:
%
%         import matlab.io.datastore.internal.RepeatedDatastore
%
%         fileNameDs = fileDatastore("patients.xls", ReadFcn=@(f) struct("Filename", f, "SheetNames", sheetnames(f)));
%
%         sheetNameDs = RepeatedDatastore(fileNameDs, @(s) numel(s.SheetNames));
%
%         sheetDataDs = sheetNameDs.transform(@(s, info) readtable(s.Filename, Sheet=info.RepetitionIndex), IncludeInfo=true);
%
%       Both "sheetNameDs" and "sheetDataDs" above will partition at maximum
%       granularity (i.e. at the sheet-level).
%
%   RPTDS = matlab.io.datastore.internal.RepeatedDatastore(DS, REPEATFCN, IncludeInfo=TF) will
%       include the "info" struct when calling REPEATFCN.
%
%       So the signature of REPEATFCN will change to:
%
%           N = REPEATFCN(data, info)
%
%       where "data" and "info" are from each read call on DS.
%
%   RPTDS = matlab.io.datastore.internal.RepeatedDatastore(DS, REPEATFCN, ..., RepeatAllFcn=@FCN)
%       registers an function that can optimize the repetition indices
%       computation when all repetition indices are requested (like when calling numpartitions()
%       or numobservations()).
%
%       FCN must have the following signature:
%
%           NumRepetitions = RepeatAllFcn(DS, RepeatFcn, IncludeInfo)
%
%       where DS is a subset of the underlying datastore used to construct the
%       RepeatedDatastore. RepeatFcn and IncludeInfo are also forwarded.
%
%       The result of RepeatAllFcn must be an N-by-1 column vector of
%       non-negative integer double values, where N is equal to the number
%       of partitions in the input datastore DS.
%
%   matlab.io.datastore.internal.RepeatedDatastore Properties:
%
%     UnderlyingDatastore      | The underlying datastore used for repetition counts                   | datastore | Read-only
%     RepeatFcn                | Function that returns the number of repetitions for the current read  | function  | Read-only
%     IncludeInfo              | Pass the "info" struct to RepeatFcn                                   | logical   | Read-only
%
%   matlab.io.datastore.internal.RepeatedDatastore Methods:
%
%     hasdata       - Returns true if there is more data in the datastore.
%     read          - Reads from the UnderlyingDatastore or returns a previous read.
%     reset         - Resets the datastore to the start.
%     preview       - Returns the first read from the UnderlyingDatastore.
%     readall       - Returns all the data that can be read.
%     partition     - Returns a new datastore that iterates over a part of the
%                     datastore.
%     numpartitions - Provides an estimate for a reasonable number of
%                     partitions.
%     subset        - Returns a new datastore that contains a subset of the
%                     data in the original datastore.
%     shuffle       - Returns a new datastore that shuffles all the data in
%                     the input datastore.
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

%   Copyright 2021-2022 The MathWorks, Inc.

    properties (SetAccess = private)
        UnderlyingDatastore      (1, 1) {mustBeSubsettableDatastore} = arrayDatastore([]);
        RepeatFcn                (1, 1) {mustBeA(RepeatFcn, "matlab.mixin.internal.FunctionObject")} = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(data) 1);
        RepeatAllFcn             (1, 1) {mustBeA(RepeatAllFcn, "matlab.mixin.internal.FunctionObject")} = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(~) 1);
        IncludeInfo              (1, 1) logical                      = false;
    end

    properties (SetAccess = private, Hidden)
        UnderlyingDatastoreIndex (1, 1) {mustBeDatastore}            = matlab.io.datastore.internal.RangeDatastore();
    end

    properties (Hidden)
        %RepetitionIndices   An incrementally populated cell containing indices
        %   of each repetition to be made.
        %
        %   The result of RepeatFcn() is stored in this array so that it doesn't have to be
        %   recomputed after reset().
        %
        %   RepetitionIndices is an incrementally computed cell array, where scalar
        %   missing values are used to signify that a particular value hasn't been
        %   computed yet.
        %
        %     % Datastore that does 2 repetitions each for the letter "a" and "b".
        %     rptds = RepeatedDatastore(arrayDatastore(["a"; "b"]), RepeatFcn=@() 2);
        %     disp(rptds.RepetitionIndices); % { missing;
        %                                    %   missing };
        %
        %   On the first read(), the datastore will compute only the first RepetitionIndices
        %   value by calling the RepeatFcn:
        %
        %     read(rptds); % {"a"}
        %     disp(rptds.RepetitionIndices); % { [1 2];     % Populated since RepeatFcn returned 2
        %                                    %   missing };
        %
        %   Now if a datastore partitioning method like numpartitions or numobservations
        %   is called on this datastore, it has to compute all the RepetitionIndices
        %   values to give a granular answer for numpartitions or numobservations:
        %
        %     numpartitions(rptds); % 4
        %     disp(rptds.RepetitionIndices); { [1 2];
        %                                      [1 2]; }; % sum of all lengths: 2 + 2 = 4
        %
        %   So computation of a specific repetition index is deferred till
        %   it is actually needed.
        RepetitionIndices        (:, 1) cell                         = cell.empty(0, 1);
    end

    properties (SetAccess = private, Hidden)

        InnerDatastore           (1, 1) {mustBeSubsettableDatastore} = arrayDatastore([]);

        % CurrentReadData   Data from the current read from the UnderlyingDatastore.
        %                   This must be cached so that we can return the same value on multiple reads.
        CurrentReadData = [];
        CurrentReadInfo = [];
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of RepeatedDatastore in R2022a.
        % ClassVersion = 2 adds RepeatAllFcn for R2023a.
        ClassVersion(1, 1) double = 2;
    end

    methods
        function rptds = RepeatedDatastore(UnderlyingDatastore, RepeatFcn, args)
            arguments
                UnderlyingDatastore (1, 1) {mustBeSubsettableDatastore}
                RepeatFcn           (1, 1)
                args.IncludeInfo    (1, 1) logical = false
                args.RepeatAllFcn   (1, 1)         = makeDefaultRepeatAllFcn()
            end
            import matlab.io.datastore.internal.functor.makeFunctionObject

            rptds.UnderlyingDatastore = copy(UnderlyingDatastore);
            rptds.RepeatFcn           = makeFunctionObject(RepeatFcn);
            rptds.IncludeInfo         = args.IncludeInfo;
            rptds.RepeatAllFcn        = makeFunctionObject(args.RepeatAllFcn);

            rptds.UnderlyingDatastore.reset();

            n = rptds.UnderlyingDatastore.numobservations();
            rptds.RepetitionIndices = repmat({missing}, n, 1);
            rptds.UnderlyingDatastoreIndex = matlab.io.datastore.internal.RangeDatastore(Start=1, End=n);
        end
    end

    methods (Access=protected)
        rptdsCopy = copyElement(rptds);
    end

    methods (Hidden)
        frac = progress(rptds);

        S = saveobj(rptds);

        result = visitUnderlyingDatastores(ds, visitFcn, combineFcn);
    end

    methods (Hidden, Static)
        rptds = loadobj(S);
    end

    methods (Static)
        function numRepeats = defaultRepeatAllFcn(uds, RepeatFcn, IncludeInfo)
            numRepeats = zeros(uds.numpartitions(), 1);

            uds.reset();
            for index = 1:uds.numpartitions()
                if IncludeInfo
                    [data, info] = uds.read();
                    numRepeats(index) = RepeatFcn(data, info);
                else
                    data = uds.read();
                    numRepeats(index) = RepeatFcn(data);
                end
            end
        end
    end
end

function mustBeDatastore(ds)
    if ~isa(ds, "matlab.io.Datastore") && ~isa(ds, "matlab.io.datastore.Datastore")
        error(message("MATLAB:io:datastore:common:validation:InvalidDatastoreInput"));
    end
end

function mustBeSubsettableDatastore(ds)
    mustBeDatastore(ds);
    if ~ds.isSubsettable()
        error(message("MATLAB:io:datastore:common:validation:MustBeSubsettable"));
    end
end

function fcn = makeDefaultRepeatAllFcn()
    import matlab.io.datastore.internal.functor.FunctionHandleFunctionObject
    fcn = FunctionHandleFunctionObject(@matlab.io.datastore.internal.RepeatedDatastore.defaultRepeatAllFcn);
end
