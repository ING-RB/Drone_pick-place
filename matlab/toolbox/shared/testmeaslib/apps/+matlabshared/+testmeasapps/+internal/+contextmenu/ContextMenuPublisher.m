classdef ContextMenuPublisher < matlabshared.mediator.internal.Publisher
    % CONTEXTMENUPUBLISHER handles publisher mechanisms for the  Context
    % MenuSource class and is instantiated by the ContextMenuSource class

    % Copyright 2022 The MathWorks, Inc.
    properties (SetObservable)
        ContextMenuRequest
    end

    methods
        function obj = ContextMenuPublisher(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
        end
    end
end