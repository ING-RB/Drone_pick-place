function validateRowIterationWithOutputTypeSame(outputType, iterationDimension, concatenationDimension)
%

%   Copyright 2020 The MathWorks, Inc.

    % Assumes that OutputType and IterationDimension have already been validated
    % separately.

    if concatenationDimension > 1
        % Use non-default ConcatenationDimension as a way to disable the error message.
        % This will only be necessary in some extreme cases.
        return;
    end

    if outputType == "same" && iterationDimension > 1
        % Ensure that only row iteration is performed when OutputType is set to same.
        % This ensures that data is vertically concatenated without any surprises when
        % readall() or read() with ReadSize > 1 is performed.
        msgid = "MATLAB:io:datastore:array:validation:OutputTypeSameRequiresRowIteration";
        error(message(msgid));
    end
end
