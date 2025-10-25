function validateStructFields(structArray, requiredFields)
%VALIDATESTRUCTFIELDS Utility to verify STRUCTARRAY has the
%required fields.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        structArray struct
        requiredFields (1, :) string
    end

    id = "MATLAB:io:arrow:arrow2matlab:MissingStructField";

    for field = requiredFields
        if ~isfield(structArray, field)
            error(message(id, field));
        end
    end
end
