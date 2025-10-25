function formatted = formatStringVector(str)
%FORMATSTRINGVECTOR Formats a columnar string vector or cellstr for display
%in an error message.

% Copyright 2022 The MathWorks, Inc.

    arguments
        str(:, 1) string
    end
    padding = newline + "    ";
    formatted = newline + padding + join(str, padding);
end
