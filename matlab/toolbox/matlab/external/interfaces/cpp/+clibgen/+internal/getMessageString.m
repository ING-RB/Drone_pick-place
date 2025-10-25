function messageString = getMessageString(msgVec)
%

%   Copyright 2024 The MathWorks, Inc.

    messageString = message(msgVec{:}).getString();
end

