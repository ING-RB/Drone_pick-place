function mapArray = buildMapArray(arrowStruct, opts)
%BUILDMAPARRAY Builds a cell array of tables from an Arrow MAP array.

% Copyright 2022 The MathWorks, Inc.
    arguments
        arrowStruct(1, 1) {mustBeArrowMapArrayStruct}
        opts(1, 1) Arrow2MatlabOptions = Arrow2MatlabOptions
    end

    import matlab.io.arrow.internal.Arrow2MatlabOptions

    numChunks = numel(arrowStruct.Data);
    mapArrayChunks = cell(numChunks, 1);

    for ii = 1:numChunks
        % Convert the keys into the appropriate MATLAB datatype.
        keys = matlab.io.arrow.internal.arrow2matlab(arrowStruct.Data(ii).Keys, opts);

        % Convert the values into the appropriate MATLAB datatype.
        values = matlab.io.arrow.internal.arrow2matlab(arrowStruct.Data(ii).Values, opts);

        % Unpack the validity bitmap into a logical array containing
        % true values at indices that correspond to the indices of null
        % elements in the arrow::MapArray.
        nullIndices = ~(matlab.io.arrow.internal.arrow2matlab(arrowStruct.Valid(ii)));
        startOffsets = arrowStruct.Data(ii).StartOffsets;

        values = table(keys, values, VariableNames=["Key", "Value"]);

        numRows = numel(startOffsets) - 1;
        mapArray = cell(numRows, 1);
        for jj = 1:numRows
            idx = (startOffsets(jj) + 1): startOffsets(jj + 1);
            mapArray{jj} = values(idx, :);
        end

        mapArray(nullIndices) = {missing};
        mapArrayChunks{ii} = mapArray;
    end

    % Vertically concatenate the chunks together into an Nx1 cell array
    mapArray = vertcat(mapArrayChunks{:});

end

function mustBeArrowMapArrayStruct(mapArrayStruct)
    import matlab.io.arrow.internal.validateStructFields

    requiredFields = ["ArrowType", "Type", "Data", "Valid"];
    validateStructFields(mapArrayStruct, requiredFields);
    if mapArrayStruct.ArrowType ~= "map"
        id = "MATLAB:io:arrow:arrow2matlab:WrongArrowType";
        error(message(id, "map", mapArrayStruct.ArrowType));
    end
end
