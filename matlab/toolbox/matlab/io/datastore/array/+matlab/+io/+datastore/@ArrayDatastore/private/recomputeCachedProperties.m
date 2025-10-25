function recomputeCachedProperties(arrds)
%recomputeCachedProperties   IndexVector and TotalNumBlocks are cached to
%   improve performance. Recompute these properties and RESET the ArrayDatastore.

%   Copyright 2022 The MathWorks, Inc.

    % Recompute the index vector since the IterationDimension may have changed.
    % This uses the current IterationDimension value on the datastore.
    arrds.IndexVector = arrds.computeIndexVector();

    % Also recompute the TotalNumBlocks since that is dependent
    % on IterationDimension.
    arrds.TotalNumBlocks = arrds.computeTotalNumBlocks();

    % NumBlocksRead needs to be set back to 0.
    arrds.reset();
end