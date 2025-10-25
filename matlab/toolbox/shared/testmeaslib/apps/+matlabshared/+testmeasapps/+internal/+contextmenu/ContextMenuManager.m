classdef ContextMenuManager < matlabshared.mediator.internal.Subscriber...
        & matlabshared.mediator.internal.Publisher

% CONTEXTMENUMANAGER class is a publisher and subscriber that is
% responsible for receiving ContextMenuRequest from ContextMenuSource
% through the mediator. It also publishes the requestFlag property
% back to the mediator to which ContextMenuMixin is listening to.
% This class is responsible for the communication between
% ContextMenuSource and ContextMenuMixin classes using the mediator
% pattern.

% Copyright 2022-2024 The MathWorks, Inc.

    properties(SetObservable)
        RequestFlag
        ContextMenuObj

    end

    methods(Access = public)
        function obj = ContextMenuManager(mediator)
            obj@matlabshared.mediator.internal.Subscriber(mediator);
            obj@matlabshared.mediator.internal.Publisher(mediator);
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            objWeakRef = matlab.lang.WeakReference(obj);
            obj.subscribe('ContextMenuRequest', @(src, event)requestContextMenu(objWeakRef.Handle));
        end

        function setContextMenuObj(obj, contextMenuObject)
            obj.ContextMenuObj = contextMenuObject;
        end

        function requestContextMenu(obj)
        % This property is set when ContextMenuRequest property is
        % set on the mediator, i.e. when a context menu is requested
            obj.RequestFlag = true;
        end

    end

end
