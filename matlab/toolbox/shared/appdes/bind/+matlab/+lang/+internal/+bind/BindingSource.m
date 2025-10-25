classdef (Abstract) BindingSource < handle
    %BINDINGSOURCE Interface for a binding source

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        start(obj, binding, sendDataFcn)
        stop(obj, binding)
    end
end

