classdef Subsettable < handle ...
                     & matlab.io.datastore.Partitionable ...
                     & matlab.io.datastore.Shuffleable
%Subsettable   An interface that adds SUBSET support to datastores
%
%   Subclasses must implement the abstract subsetByReadIndices and maxpartitions
%   method when deriving from this mixin.
%
%   This mixin implements the following methods for any subclass:
%    - SUBSET: Create a new datastore that reads a subset of the original data
%    - PARTITION and NUMPARTITIONS: Create balanced partitions of a datastore
%    - SHUFFLE: Shuffle the data in a datastore
%
%   Therefore any subclass of this mixin will return true for the isPartitionable,
%   isShuffleable, and isSubsettable methods.
%
%   NOTE: It is recommended to implement Subsettable only for datastores in which
%         every read can be accessed independently.
%         If this is not possible (i.e. there are dependencies between reads), consider
%         implementing only the Partitionable mixin instead.
%
%   NOTE: When checking for subsettability on a datastore, the "isSubsettable" method
%         should be used instead of performing isa(ds, "matlab.io.datastore.Subsettable").
%         Some datastores may be Subsettable even if they do not derive from this mixin.
%         Some datastores (like CombinedDatastore) may not be subsettable even if they
%         do derive from this mixin.
%
%   Subsettable Methods:
%
%       subset              - Return a new datastore with the specified read indices.
%       subsetByReadIndices - Use the specified read indices to construct a new datastore.
%       maxpartitions       - Return the maximum number of partitions possible for
%                             the datastore.
%       shuffle             - Return a new datastore that shuffles all the
%                             data in the input datastore.
%       partition           - Return a new datastore that represents a single
%                             partitioned part of the original datastore.
%       numpartitions       - Return an estimate for a reasonable number of
%                             partitions to use with the partition function for
%                             the given information.
%
%   Subsettable Method Attributes:
%
%       subset              - Public
%       subsetByReadIndices - Protected, Abstract
%       maxpartitions       - Protected, Abstract
%       shuffle             - Public
%       partition           - Public
%       numpartitions       - Public, Sealed
%
%   Default implementations of PARTITION and SHUFFLE are
%   provided through this mixin for convenience. Datastore authors are
%   encouraged to override or hide these methods as desired.
%
%   See also SUBSET, NUMPARTITIONS, isSubsettable, matlab.io.datastore.Shuffleable,
%            PARTITION, matlab.io.datastore.Partitionable, matlab.io.Datastore

%   Copyright 2019-2022 The MathWorks, Inc.

    methods (Abstract, Access = protected)
        %SUBSETBYREADINDICES   creates a new datastore with the specified read indices
        %
        %   SUBDS = SUBSETBYREADINDICES(DS, INDICES) creates a deep copy of the input
        %   datastore DS containing reads corresponding to INDICES.
        %
        %   DS will be a datastore (subclass of matlab.io.Datastore) that returns
        %   isSubsettable true.
        %
        %   INDICES will be a column vector of positive integer double values.
        %   INDICES can be a 0-by-1 empty double array and does not need
        %   to be provided in any sorted order when nonempty.
        %   INDICES may contain duplicate values.
        %
        %   The output datastore SUBDS should contain reads
        %   corresponding to INDICES and in the same order as INDICES.
        %
        %   See also matlab.io.Datastore.isSubsettable
        subds = subsetByReadIndices(ds, indices);

        %MAXPARTITIONS   the maximum index for partition and subset
        %
        %   All integer values between 1 and MAXPARTITIONS are valid indices for the
        %   SUBSET method. If MAXPARTITIONS returns 0, then SUBSET will only allow empty
        %   vectors as input.
        %
        %   DS is a datastore that returns isSubsettable true.
        %   N should be a non-negative numeric scalar.
        %
        %   See also isSubsettable, SUBSET
        n = maxpartitions(ds);
    end

    methods
        function subds = subset(ds, indices)
        %SUBSET   returns a new datastore with the specified read indices
        %
        %   SUBDS = SUBSET(DS, INDICES) creates a deep copy of the input
        %   datastore DS containing reads corresponding to INDICES.
        %
        %   DS must be a datastore that returns isSubsettable true.
        %
        %   INDICES must be a vector of positive integer numeric
        %   values. INDICES can be an empty array and does not need
        %   to be provided in any sorted order when nonempty.
        %
        %   The output datastore SUBDS, contains the reads
        %   corresponding to INDICES and in the same order as INDICES.
        %
        %   INDICES can also be specified as an N-by-1 vector of logical
        %   values, where N is the number of reads in the datastore.
        %
        %   On Subsettable datastores, the number of reads matches the
        %   maximum number of partitions. Use the NUMPARTITIONS function
        %   to find the maximum number of reads in a datastore.
        %
        %   See also NUMPARTITIONS, isSubsettable

            % Validate that the input datastore is Subsettable.
            ds.verifySubsettable();

            % Validate the indices input and convert logical to double.
            import matlab.io.datastore.internal.validators.validateSubsetIndices
            indices = validateSubsetIndices(indices, ds.maxpartitions(), "Subsettable", false);

            % Make sure that indices is a double column vector.
            indices = reshape(indices, [], 1);
            indices = double(indices);

            % Call the subclass method to generate the new datastore.
            subds = ds.subsetByReadIndices(indices);
        end

        function shufds = shuffle(ds)
        %SHUFFLE Return a shuffled version of a datastore
        %
        %   SHUFDS = SHUFFLE(DS) returns a randomly shuffled copy of a
        %   datastore.
        %
        %   See also matlab.io.datastore.Shuffleable.

            % Compute the subset indices to shuffle.
            indices = randperm(ds.maxpartitions());

            % Return a new datastore with these indices.
            shufds = ds.subset(indices);
        end

        function partds = partition(ds, partitionStrategy, partitionIndex)
        %PARTITION Return a partitioned part of the Datastore.
        %
        %   PARTDS = PARTITION(DS,N,INDEX) partitions DS into
        %   N parts and returns the partitioned Datastore, PARTDS,
        %   corresponding to INDEX. An estimate for a reasonable value for
        %   N can be obtained by using the NUMPARTITIONS function.
        %
        %   See also matlab.io.datastore.Partitionable, numpartitions,
        %   maxpartitions.

            % Validate inputs.
            validateattributes(partitionStrategy, {'numeric'}, ...
                {'scalar', 'integer', 'positive'}, ...
                "partition", "NumPartitions");

            validateattributes(partitionIndex, {'numeric'}, ...
                {'scalar', 'integer', 'positive', '<=', partitionStrategy}, ...
                "partition", "PartitionIndex");

            % Get the necessary observation indices.
            indices = matlab.io.datastore.internal.util.pigeonHole(...
                partitionStrategy, ds.maxpartitions(), partitionIndex);

            % Return a subset with these observation indices.
            partds = ds.subset(indices);
        end
    end

    methods (Hidden)
        %NUMOBSERVATIONS   the number of observations in this datastore
        %
        %   This has been defined for compatibility with the legacy
        %   (internal-only) matlab.io.datastore.mixin.Subsettable mixin.
        %
        %   See also matlab.io.datastore.mixin.Subsettable.subset
        function n = numobservations(ds)
            n = ds.maxpartitions();
        end
    end

    methods (Access = protected)
        %verifySubsettable   throws if the datastore returns isSubsettable=false
        %
        %   This method can be overridden to customize the error thrown when subset()
        %   is called but the datastore is not subsettable in its current state.
        function verifySubsettable(ds)
            if ~ds.isSubsettable()
                msgid = "MATLAB:io:datastore:common:validation:MustBeSubsettable";
                error(message(msgid));
            end
        end
    end
end
