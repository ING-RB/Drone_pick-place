function builder = TableBuilder2TimetableBuilder(builder, varargin)
%TableBuilder2TimetableBuilder   Converts a TableBuilder to a
%   TimetableBuilder.
%
%   Will error if RowTimes cannot be inferred from the VariableTypes in the
%   TableBuilder.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        builder (1, 1) matlab.io.internal.common.builder.TableBuilder
    end

    arguments (Repeating)
        varargin
    end

    builder = matlab.io.internal.common.builder.TimetableBuilder("TableBuilder", builder, varargin{:});
end