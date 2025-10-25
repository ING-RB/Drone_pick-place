function unit = checkUnit(unitIn)
%CHECKUNIT Validate unit for duration math and return the corresponding scaling factor.
%   UNIT = CHECKUNIT(UNITIN) validates that UNITIN is a supported unit for
%   duration math and returns the scaling factor from UNITIN to
%   milliseconds.

%   Copyright 2014-2020 The MathWorks, Inc.

try
    scale = [1000 60000 3600000 86400000 31556952000]; % "standard" units expressed in ms]
    unit = scale(matlab.internal.datatypes.getChoice(unitIn,{'seconds'; 'minutes'; 'hours'; 'days'; 'years'},["MATLAB:duration:units:InvalidUnit","MATLAB:duration:units:AmbiguousUnit"]));
catch ME
    throwAsCaller(ME);
end
