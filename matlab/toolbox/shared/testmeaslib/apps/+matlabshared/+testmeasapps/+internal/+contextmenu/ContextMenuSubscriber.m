classdef ContextMenuSubscriber < matlabshared.mediator.internal.Subscriber
    % CONTEXTMENUSUBSCRIBER handles subscriber mechanisms for the Context
    % MenuSource class and is instantiated by the ContextMenuSource class

    % Copyright 2022 The MathWorks, Inc.

    properties
        ContextMenuObj
    end

    methods
        function obj = ContextMenuSubscriber(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj,~,~)
            obj.subscribe('ContextMenuObj', @(src,evt) obj.handleContextMenuObj(evt.AffectedObject.ContextMenuObj));
        end

        function handleContextMenuObj(obj, contextMenuObject)
            % This class has subscribed to ContextMenuObj, so when it is
            % set on the mediator, handleContextMenuObj() method is
            % executed which gets this Context Menu object from the mediator
            obj.ContextMenuObj = contextMenuObject;
        end
    end
end
