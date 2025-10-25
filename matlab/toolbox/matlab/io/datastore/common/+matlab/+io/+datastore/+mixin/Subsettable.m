classdef Subsettable < matlab.io.datastore.Partitionable ...
                     & matlab.io.datastore.Shuffleable
%Subsettable   Expresses observation-level partitionability of a datastore
%   Datastores that derive from this mixin are supported for partitioning 
%   and shuffling in a CombinedDatastore.
%
%   Datastore authors must ensure that any deriving datastores are truly 
%   operating at the observation level, i.e. an observation must be a 
%   single row table or a single row cell array.
%   
%   Subsettable Methods:
%
%   subset          - Return a new datastore that contains the observations
%                     corresponding to the input indices.
%   numobservations - Return the total number of observations in the
%                     datastore.
%   shuffle         - Return a new datastore that shuffles all the
%                     observations in the input datastore.
%   partition       - Return a new datastore that represents a single
%                     partitioned part of the original datastore.
%   numpartitions   - Return an estimate for a reasonable number of
%                     partitions to use with the partition function for
%                     the given information.
%   maxpartitions   - Return the maximum number of partitions possible for
%                     the datastore.
%
%   Subsettable Method Attributes:
%
%   subset          - Public, Abstract
%   numobservations - Public, Abstract
%   shuffle         - Public
%   partition       - Public
%   numpartitions   - Public, Sealed
%   maxpartitions   - Protected
%
%   Default implementations of PARTITION, MAXPARTITIONS, and SHUFFLE are
%   provided through this mixin for convenience. Datastore authors are
%   encouraged to override or hide these methods as desired.
% 
%   See also matlab.io.datastore.Shuffleable, matlab.io.Datastore

%   Copyright 2019 The MathWorks, Inc.

    methods (Abstract)
        %SUBSET   returns a new datastore with the specified observation indices
        %
        %   SUBDS = SUBSET(DS, INDICES) creates a deep copy of the input
        %   datastore DS containing observations corresponding to INDICES.
        %
        %   DS must be a valid datastore that returns isSubsettable true.
        %
        %   INDICES must be a vector of positive and unique integer numeric
        %   values. INDICES can be a 0-by-1 empty array and does not need 
        %   to be provided in any sorted order when nonempty.
        %
        %   The output datastore SUBDS, contains the observations
        %   corresponding to INDICES and in the same order as INDICES.
        %
        %   INDICES can also be specified as a N-by-1 vector of logical
        %   values, where N is the number of observations in the datastore.
        %
        %   See also matlab.io.Datastore.isSubsettable, 
        %   matlab.io.datastore.mixin.Subsettable.numobservations, 
        %   matlab.io.datastore.ImageDatastore.subset, 
        %   matlab.io.datastore.internal.validators.validateSubsetIndices
        subds = subset(ds, indices);

        %NUMOBSERVATIONS   the number of observations in this datastore
        %
        %   N = NUMOBSERVATIONS(DS) returns the number of observations in
        %   the current datastore state. 
        %
        %   All integer values between 1 and N are valid indices for the 
        %   SUBSET method.
        %
        %   DS must be a valid datastore that returns isSubsettable true.
        %   N is a non-negative double scalar.
        %   
        %   See also matlab.io.Datastore.isSubsettable,
        %   matlab.io.datastore.mixin.Subsettable.subset
        n = numobservations(ds);
    end
    
    methods
        function shufds = shuffle(ds)
        %SHUFFLE Return a shuffled version of a datastore
        %
        %   NEWDS = SHUFFLE(DS) returns a randomly shuffled copy of a
        %   datastore.
        %
        %   See also matlab.io.datastore.Shuffleable.

            % Compute the subset indices to shuffle.
            indices = randperm(ds.numobservations());
            
            % Return a new datastore with these indices.
            shufds = ds.subset(indices);
        end
        
        function partds = partition(ds, partitionStrategy, partitionIndex)
        %PARTITION Return a partitioned part of the Datastore.
        %
        %   SUBDS = PARTITION(DS,N,INDEX) partitions DS into
        %   N parts and returns the partitioned Datastore, SUBDS,
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
                partitionStrategy, ds.numobservations(), partitionIndex);
            % Return a subset with these observation indices.
            partds = ds.subset(indices);
        end
    end
    
    methods (Access = protected)
        function n = maxpartitions(ds)
        %MAXPARTITIONS Return the maximum number of partitions possible for
        % the datastore.
        %
        %   N = MAXPARTITIONS(DS) returns the maximum number of partitions for a
        %   given Datastore, DS.
        %
        %   See also matlab.io.datastore.Partitionable, numpartitions,
        %   partition.
        
            n = ds.numobservations();
        end
    end
end