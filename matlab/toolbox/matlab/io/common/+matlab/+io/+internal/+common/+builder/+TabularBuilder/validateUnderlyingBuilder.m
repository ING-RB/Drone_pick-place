function validateUnderlyingBuilder(builder)
%validateUnderlyingBuilder   Verifies that the builder is either a
%   TableBuilder or TimetableBuilder.

%   Copyright 2022 The MathWorks, Inc.

    mustBeA(builder, ["matlab.io.internal.common.builder.TableBuilder";
                      "matlab.io.internal.common.builder.TimetableBuilder"])
end