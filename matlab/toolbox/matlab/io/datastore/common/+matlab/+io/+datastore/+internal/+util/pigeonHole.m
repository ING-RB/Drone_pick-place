function observationIndices = pigeonHole(numPartitions, numObservations, partitionIndex)
%PIGEONHOLE   Maps number of observations to the number of partitions
%   This helper function to the partition method maps the observations to
%   the partitions. This function avoids floating-point errors by
%   converting inputs to unsigned integers. The logic applied is the
%   following: get the quotient from dividing number of observations by
%   number of partitions. This is the minimum number of observations per
%   partition. Then, get the remainder (mod) of dividing the number of
%   observations by number of partitions. This is the overflow, p, which is
%   strictly bound by 0 <= p < N, where N is the number of partitions.
%   These p observations are inserted into the first p partitions. This
%   function takes an optional third argument and returns only the indices
%   for the specific partition.

%   Copyright 2020 The MathWorks, Inc.

    % convert numObservations and numPartitions to integer values so there
    % are no floating-point division errors
    numObservations = uint64(numObservations);
    numPartitions = uint64(numPartitions);
    
    % calculate the quotient of dividing numObervations by numPartitions
    minNumberPerPartition = idivide(numObservations,numPartitions, 'floor');
    % calculate the remainder of dividing numObervations by numPartitions
    overFlow = mod(numObservations,numPartitions);

    % create the initial vector of partitions
    v = 1 : numPartitions;
    % replicate the partitions minNumPerPartition number of times
    observationIndices = repmat(v, minNumberPerPartition, 1);
    if overFlow
        % add another row to the matrix which will contain zeros
        tempVal = zeros(1, size(v,2));
        tempVal(1 : overFlow) = 1 : overFlow;
        observationIndices(end+1, :) = tempVal;
    end

    % Convert back to double
    observationIndices = double(observationIndices(:)');
    % remove the zeros
    observationIndices(~observationIndices) = [];
    % for call from Subsettable
    if nargin >= 3
        observationIndices = find(observationIndices == partitionIndex);
    end
    % Convert to a vector if observationIndices is empty.
    if isempty(observationIndices)
        observationIndices = double.empty(0, 1);
    end
end
