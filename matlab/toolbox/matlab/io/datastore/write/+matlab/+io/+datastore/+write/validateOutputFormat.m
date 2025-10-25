function validateOutputFormat(outFmt, supportedOutFmts)
%validateOutputFormat    Validate that the supplied output format is an
%   acceptable value based on the datastore

%   Copyright 2023 The MathWorks, Inc.
    % Ensure that the user has provided a valid value for OutputFormat.
    validatestring(outFmt, unique(supportedOutFmts), "writeall", "OutputFormat");
end
