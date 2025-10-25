classdef (Abstract) ContextMenuMixin < handle
% CONTEXTMENUMIXIN is the class that the HWMGR client apps will
% inherit from along with AppletBase to get the Convenience API for
% context menu

% Copyright 2022-2024 The MathWorks, Inc.

    properties
        ContextMenuManager
        ContextMenuListener
    end

    methods
        function obj = ContextMenuMixin(mediator)
        % Check if the argument is a mediator
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            % Setting up a ContextMenuManager which is responsible for
            % establishing communication between ContextMenuSource and
            % ContextMenuMixin.
            obj.ContextMenuManager = matlabshared.testmeasapps.internal.contextmenu.ContextMenuManager(...
                mediator);

            objWeakRef = matlab.lang.WeakReference(obj);
            obj.ContextMenuListener = obj.ContextMenuManager.listener('RequestFlag',...
                                                                      'PostSet', @(src,event)requestContextMenu(objWeakRef.Handle));

        end

        function requestContextMenu(obj)
            cm = createContextMenu(obj);
            obj.ContextMenuManager.setContextMenuObj(cm);

        end
    end

    methods(Abstract)
        % The implementation for this method is present in
        % matlab.hwmgr.internal.ContextMenuMixin
        cm = createContextMenu(obj);
    end
end
