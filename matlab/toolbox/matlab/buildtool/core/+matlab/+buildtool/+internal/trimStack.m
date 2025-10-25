function stack = trimStack(stack)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2022-2023 The MathWorks, Inc.

arguments
    stack (:,1) struct
end

import matlab.automation.internal.services.stacktrimming.StackTrimmingLiaison
import matlab.buildtool.internal.services.stacktrimming.CoreFrameworkStackTrimmingService

liaison  = StackTrimmingLiaison(stack);
services = CoreFrameworkStackTrimmingService; % no located services, for now
fulfill(services, liaison);
stack = liaison.Stack;

end
