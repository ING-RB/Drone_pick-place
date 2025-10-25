classdef ViewModelOperationPlaceholder < handle
    %VIEWMODELOPERATIONPLACEHOLDER An interface to queue ViewModel operation
    % in ParallelRenderingViewModelPlaceholder
    
    % Copyright 2024 MathWorks, Inc.

    methods (Abstract)
        attach(vm);
    end
end

