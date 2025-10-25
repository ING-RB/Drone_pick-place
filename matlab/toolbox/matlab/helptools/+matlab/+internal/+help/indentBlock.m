function block = indentBlock(block)
    block = replace(block, newline + ~textBoundary, newline + indent);
end

%   Copyright 2022-2024 The MathWorks, Inc.
