function str = indent(scale)
    arguments
        scale (1,1) double {mustBeMember(scale, 0.5:0.5:2)} = 1;
    end
    fullWidth = 4;
    str = string(blanks(fullWidth*scale));
end

%   Copyright 2021-2022 The MathWorks, Inc.
