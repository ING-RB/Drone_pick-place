classdef DialogSourcePublisher < matlabshared.mediator.internal.Publisher
    %DIALOGSOURCEPLUBLISHER handles publisher mechanisms for the Dialog
    %Source class and is instantiated by the DialogSource class.

    %   Copyright 2022 The MathWorks, Inc.
    properties (SetObservable)
        ErrorObj
        WarningObj
        OptionObj
    end

    methods
        function obj = DialogSourcePublisher(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            obj@matlabshared.mediator.internal.Publisher(mediator);
        end
    end
end