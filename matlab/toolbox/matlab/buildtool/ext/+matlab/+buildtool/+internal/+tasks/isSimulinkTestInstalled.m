function tf = isSimulinkTestInstalled()
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

tf = ~isempty(ver("simulinktest"));
end