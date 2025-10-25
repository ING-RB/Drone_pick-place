classdef DialogRequestReceiver < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber
    %DIALOGREQUESTRECEIVER class is a publisher and subscriber that is
    %responsible for receiving mediator published ErrorObj, WarningObj, and
    %OptionObj values from the DialogSource. It also publishes the user's
    %response to a confirmation dialog - OptionsResponse back to the
    %DialogSource.
    % This class relays information from the DialogSource to the
    % DialogMixin class and vice-versa.

    %   Copyright 2021 The MathWorks, Inc.

    properties (SetObservable)
        ErrorObject
        WarningObject
        OptionObject
        OptionsResponse
    end

    methods
        function obj = DialogRequestReceiver(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end
    end

    %% Subscriber methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe ...
                ("ErrorObj", @(~, evt)obj.setErrorObject(evt.AffectedObject.ErrorObj));

            obj.subscribe ...
                ("WarningObj", @(~, evt)obj.setWarningObject(evt.AffectedObject.WarningObj));

            obj.subscribe ...
                ("OptionObj", @(~, evt)obj.setOptionObject(evt.AffectedObject.OptionObj));
        end
    end

    methods
        function setErrorObject(obj, errorObj)
            obj.ErrorObject = errorObj;
        end

        function setWarningObject(obj, warningObj)
            obj.WarningObject = warningObj;
        end

        function setOptionObject(obj, optionObj)
            obj.OptionObject = optionObj;
        end

        function setOptionsResponse(obj, optionsResponse)
            obj.OptionsResponse = optionsResponse;
        end
    end
end
