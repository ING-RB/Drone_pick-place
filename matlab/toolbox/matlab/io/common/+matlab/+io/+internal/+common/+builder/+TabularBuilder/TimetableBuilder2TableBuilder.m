function builder = TimetableBuilder2TableBuilder(builder)
%TimetableBuilder2TableBuilder   Converts a TimetableBuilder to a
%   TableBuilder.
%
%   Since TimetableBuilder embeds a TableBuilder, this should always
%   succeed. It basically just "forgets" the RowTimes setting.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        builder (1, 1) matlab.io.internal.common.builder.TimetableBuilder
    end

    builder = builder.Options.TableBuilder;
end