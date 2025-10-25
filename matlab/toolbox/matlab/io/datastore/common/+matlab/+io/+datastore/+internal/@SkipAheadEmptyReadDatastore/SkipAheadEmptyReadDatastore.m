classdef SkipAheadEmptyReadDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.internal.ComposedDatastore
%matlab.io.datastore.internal.SkipAheadEmptyReadDatastore  Skips through the reads
%   of the input datastore.
%
%   SAERDS = matlab.io.datastore.internal.SkipAheadEmptyReadDatastore(DS, EmptyFcn=FCN)
%       returns a new datastore SAERDS that guarantees that either each
%       read of DS will produce non-empty data. The exception to that guarantee is when the current
%       partition and all following partitions hold empty data, in which
%       case, it will return empty data.
%       The EmptyFcn, FCN, must have the following signature:
%
%           function TF = EmptyFcn(data)
%       where data is the from the output of the underlying datastore, DS. The value
%       returned by EmptyFcn, TF, must be a logical.
%
%
%
%   SAERDS = matlab.io.datastore.internal.SkipAheadEmptyReadDatastore(..., IncludeInfo=TF)
%       specifies whether the info struct should be included when calling EmptyFcn.
%       By default IncludeInfo is set to false.
%
%       If IncludeInfo is set to true, the SizeFcn must have the following signature:
%
%           function TF = EmptyFcn(data, info)
%
%
%   matlab.io.datastore.internal.SkipAheadEmptyReadDatastore Properties:
%
%     UnderlyingDatastore - The underlying datastore.
%     EmptyFcn            - Function handle or FunctionObject used to determine whether
%                           the data from a read would be empty.
%
%   See also: arrayDatastore, matlab.io.datastore.internal.ComposedDatastore

%   Copyright 2022 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore  = arrayDatastore([]);
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of SkipAheadEmptyReadDatastore in R2023b.
        ClassVersion(1, 1) double = 1;
    end

    properties (Access = private)
        EmptyFcn            (1, 1) {mustBeA(EmptyFcn, "matlab.mixin.internal.FunctionObject")} = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(func) 1);
        IncludeInfo         (1, 1) logical                     = false;
    end

    methods (Access = private)

        function tf = executeEmptyFcn(ds, data, info)
            if (ds.IncludeInfo)
                tf = ds.EmptyFcn(data, info);
            else
                tf = ds.EmptyFcn(data);
            end
        end

    end




    methods
        function saerds = SkipAheadEmptyReadDatastore(UnderlyingDatastore, Args)
            arguments
                UnderlyingDatastore (1, 1)  {matlab.io.datastore.internal.validators.mustBeDatastore}
                Args.EmptyFcn       (1, 1)
                Args.IncludeInfo    (1, 1)  logical = false
            end

            import matlab.io.datastore.internal.functor.makeFunctionObject

            % Copy and reset the input datastore on construction.
            saerds.UnderlyingDatastore = UnderlyingDatastore.copy();
            saerds.reset();

            saerds.EmptyFcn = makeFunctionObject(Args.EmptyFcn);
            saerds.IncludeInfo = Args.IncludeInfo;
        end

    end

    methods (Hidden)
        S = saveobj(schds);
    end

    methods (Hidden, Static)
        schds = loadobj(S);
    end
end
