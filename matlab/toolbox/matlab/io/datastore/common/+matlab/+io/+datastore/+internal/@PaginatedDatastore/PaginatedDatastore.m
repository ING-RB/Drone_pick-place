classdef PaginatedDatastore < matlab.io.Datastore ...
                            & matlab.io.datastore.internal.ComposedDatastore
%matlab.io.datastore.internal.PaginatedDatastore   Pages through the reads
%   of the input datastore.
%
%   PGDS = matlab.io.datastore.internal.PaginatedDatastore(DS, ReadSize=SZ)
%       returns SZ rows at a time from each read of DS.
%
%   NOTE: This datastore is not subsettable. Partition occurs at the
%   granularity of the input datastore DS.
%
%   matlab.io.datastore.internal.PaginatedDatastore Properties:
%
%     UnderlyingDatastore - The underlying datastore.
%     ReadSize            - Number of rows to return, specified as a
%                           positive integer scalar double.
%
%   See also: arrayDatastore, matlab.io.datastore.internal.ComposedDatastore

%   Copyright 2022 The MathWorks, Inc.

    properties (Access = protected)
        UnderlyingDatastore = arrayDatastore([]);
    end

    properties (Dependent)
        ReadSize
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of PaginatedDatastore in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    properties (Constant)
        NestedDatastoreClassName = "matlab.io.datastore.internal.NestedDatastore";
        ArrayDatastoreClassName  = "matlab.io.datastore.ArrayDatastore";
    end

    methods
        function pgds = PaginatedDatastore(UnderlyingDatastore, Args)
            arguments
                UnderlyingDatastore (1, 1)  {matlab.io.datastore.internal.validators.mustBeDatastore}
                Args.ReadSize       (1, 1) double {mustBePositive, mustBeInteger}
            end

            % Copy and reset the input datastore on construction.
            uds = UnderlyingDatastore.copy();
            uds.reset();

            % Use NestedDatastore and ArrayDatastore to do the actual
            % pagination work.
            import matlab.io.datastore.internal.functor.PaginationFunctionObject
            uds = uds.nest(PaginationFunctionObject(Args.ReadSize), IncludeInfo=true);

            pgds.UnderlyingDatastore = uds;
        end

        function sz = get.ReadSize(pgds)
            % Get the ReadSize from the ArrayDatastore generator function.
            fcn = pgds.getUnderlyingDatastore(pgds.NestedDatastoreClassName).InnerDatastoreFcn;
            sz = fcn.ReadSize;
        end

        function set.ReadSize(pgds, ReadSize)
            arguments
                pgds
                ReadSize (1, 1) double {mustBePositive, mustBeInteger}
            end
            % Change the ReadSize on the current paginating ArrayDatastore.
            innerDs = getUnderlyingDatastore(pgds, pgds.NestedDatastoreClassName).InnerDatastore;
            arrds = innerDs.getUnderlyingDatastore(pgds.ArrayDatastoreClassName);
            if ~isempty(arrds) % Can be empty right after construction due to NestedDatastore's default value.
                arrds.ReadSize = ReadSize;
            end

            % Also change the ReadSize on the ArrayDatastore generator so
            % that all future pages have the new ReadSize too.
            fcn = getUnderlyingDatastore(pgds, pgds.NestedDatastoreClassName).InnerDatastoreFcn;
            fcn.ReadSize = ReadSize;
        end
    end

    methods (Hidden)
        S = saveobj(schds);
    end

    methods (Hidden, Static)
        schds = loadobj(S);
    end
end
