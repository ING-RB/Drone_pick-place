classdef DialogSourceSubscriber < matlabshared.mediator.internal.Subscriber
%DIALOGSOURCESUBSCRIBER handles subscriber mechanisms for the Dialog
%Source class and is instantiated by the DialogSource class.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties
        OptionsResponse (1, 1) string
    end

    methods
        function obj = DialogSourceSubscriber(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            objWeakRef = matlab.lang.WeakReference(obj);
            obj.subscribe("OptionsResponse", ...
                          @(src, event)objWeakRef.Handle.setOptionsResponse(event.AffectedObject.OptionsResponse));
        end

        function setOptionsResponse(obj, response)
            obj.OptionsResponse = response;
        end
    end
end
