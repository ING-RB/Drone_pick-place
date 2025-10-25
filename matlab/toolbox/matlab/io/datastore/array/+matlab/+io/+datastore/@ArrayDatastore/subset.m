function newds = subset(arrds, subsetIndices)
%SUBSET   Create a new ArrayDatastore containing a subset of the input ArrayDatastore.
%
%   SUBDS = subset(ARRDS, INDICES) returns a new ArrayDatastore SUBDS that contains
%   a subset of the data from the input ArrayDatastore ARRDS.
%
%   INDICES can be specified as a numeric or logical vector of indices.

%   Copyright 2020 The MathWorks, Inc.
    import matlab.io.datastore.internal.validators.validateSubsetIndices;
    try
        subsetIndices = validateSubsetIndices(subsetIndices, ...
                                              arrds.numobservations(), ...
                                              'matlab.io.datastore.ArrayDatastore', ...
                                              false); % Can have repeated indices.
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
 
    % Subset the data using the provided indices.
    subsrefIndices = arrds.computeSubsrefIndices(subsetIndices);
    newdata = arrds.Data(subsrefIndices{:});

    newds = matlab.io.datastore.ArrayDatastore(newdata, IterationDimension=arrds.IterationDimension, ...
                                                        ReadSize=arrds.ReadSize, ...
                                                        OutputType=arrds.OutputType, ...
                                                        ConcatenationDimension=arrds.ConcatenationDimension);
end