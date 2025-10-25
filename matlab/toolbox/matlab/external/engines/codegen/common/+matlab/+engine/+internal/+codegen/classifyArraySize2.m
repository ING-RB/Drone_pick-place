function [classification trueDim] = classifyArraySize2(arraySize)
    %classifyArraySize2 Classify array type as scalar, vector, or higher.
    %Given the size as an array of ArrayDimensions, determine if the array
    %is scalar, vector, or higher dimensional. Also return "true dimension"
    %which is number of non-trivial dimensions.

    arguments (Input)
        arraySize {mustBeA(arraySize, ["matlab.internal.metadata.ArrayDimension", "meta.ArrayDimension"])} % TODO - these ArrayDimension APIs are going to be merged, simplify this when that happens
    end
    
    arguments (Output)
        classification (1,1) matlab.engine.internal.codegen.DimType
        trueDim (1,1) int64 % Number of dimensions which may have length>1. Value is -1 if array is empty. Assume number dimensions <2^63-1.
    end

    import matlab.engine.internal.codegen.DimType;

    n = length(arraySize); % simple dimension metric
    classification = DimType.Unknown; % assume unknown until classified
    trueDim = -1; % -1 is special empty value. Initially assert empty.

    % Need at least 2 length definitions to not be empty (e.g. 1 by : is valid, but 1 by nothing must be empty)
    if n<2
        classification = DimType.Empty;
        trueDim = -1;
        return
    end

    lengthGtOne = 0; % Holds number of lengths in array that are greater than 1

    % Loop through each dimension since we are not sure if it's a FixedDimension or UnrestrictedDimension
    for k = 1:length(arraySize)
        dim = arraySize(k);
        if isa(dim, "matlab.internal.metadata.FixedDimension") || isa(dim, "meta.FixedDimension")

            % If any dimension has length of 0, the array must be empty
            if dim.Length == 0
                classification = DimType.Empty;
                trueDim = -1;
                return; % need not examine other dimensions

                % Increment lengths greater than one if applicable
            elseif dim.Length > 1
                lengthGtOne = lengthGtOne + 1;
            end

        elseif isa(dim, "matlab.internal.metadata.UnrestrictedDimension") || isa(dim, "meta.UnrestrictedDimension")
            % If a dimension is "unrestricted" (for example "(1,:)" is unrestricted in second position)
            % then consider the length to be non-trivial / greater than 1
            lengthGtOne = lengthGtOne + 1;
        end

    end

    % Based on non-trivial (non-1-sized) dimensions, determine type
    if lengthGtOne == 0
        classification = DimType.Scalar; % for example 1x1x1 or 1x1
    elseif lengthGtOne == 1
        classification = DimType.Vector; % for example 1x1x2 or 1x:
    elseif lengthGtOne >=2
        classification = DimType.MultiDim; % for example 2x2x1
    end

    trueDim = lengthGtOne; % Array is not empty (-1 case), so return number of lengthy dimensions
end

