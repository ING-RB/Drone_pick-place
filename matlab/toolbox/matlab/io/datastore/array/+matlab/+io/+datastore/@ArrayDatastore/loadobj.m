function arrds = loadobj(S)
%

%   Copyright 2020 The MathWorks, Inc.

    if isfield(S, "EarliestSupportedVersion")
        % Error if we are sure that a version incompatibility is about to occur.
        if S.EarliestSupportedVersion > matlab.io.datastore.ArrayDatastore.ClassVersion
            error(message("MATLAB:io:datastore:array:validation:UnsupportedArrayDatastoreVersion"));
        end
    end

    % Reconstruct the object.
    arrds = matlab.io.datastore.ArrayDatastore(S.Data, ...
                 "OutputType", S.OutputType, ...
                 "ReadSize", S.ReadSize, ...
                 "IterationDimension", S.IterationDimension, ...
                 "ConcatenationDimension", S.ConcatenationDimension);

    % Recover the iterator position.
    arrds.NumBlocksRead = S.NumBlocksRead;
end
