function cart = readCartesian(scan)
%This function is for internal use only. It may be removed in the future.

%readCartesian Convert ranges and angles to Cartesian coordinates
%   This function also ignores any NaN or Inf range readings.

%   Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% Check for NaN/Inf values and remove those rows
    scan = removeInvalidData(scan);

    % Return Cartesian coordinates
    cart = scan.Cartesian;

end
