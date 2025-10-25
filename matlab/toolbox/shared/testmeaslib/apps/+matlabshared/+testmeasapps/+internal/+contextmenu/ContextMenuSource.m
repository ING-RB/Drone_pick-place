classdef (Abstract) ContextMenuSource < handle
    % CONTEXTMENUSOURCE is the class which the HWMGR Client Apps will inherit
    % from in their Manager/Controller classes to get the context menu
    % functionality

    % Copyright 2022 The MathWorks, Inc.

    properties(Hidden, Dependent)
        ContextMenuRequest
    end

    properties
        % These facilitate subscribing and publishing for ContextMenuSource
        ContextMenuSubscriber
        ContextMenuPublisher
    end

    properties(Dependent)
        ContextMenuObj
    end

    methods
        function obj = ContextMenuSource(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end
            obj.ContextMenuPublisher = ...
                matlabshared.testmeasapps.internal.contextmenu.ContextMenuPublisher(mediator);
            obj.ContextMenuSubscriber = ...
                matlabshared.testmeasapps.internal.contextmenu.ContextMenuSubscriber(mediator);
        end
    end

    methods
        function result = requestContextMenu(obj)
            % This property is set to true when a context menu is requested, 
            % and setting it to true actually publishes the ContextMenuRequest 
            % property to the mediator
            obj.ContextMenuRequest = true;

            % This is the new context menu object
            result = obj.ContextMenuObj;   
        end
    end

    methods
        %% Getter Mehtods
        function val = get.ContextMenuObj(obj)
            val = obj.ContextMenuSubscriber.ContextMenuObj;
        end

        function val = get.ContextMenuRequest(obj)
            val = obj.ContextMenuPublisher.ContextMenuRequest;
        end

        %% Setter Methods
        function set.ContextMenuObj(obj, val)
            obj.ContextMenuSubscriber.ContextMenuObj = val;
        end

        function set.ContextMenuRequest(obj, val)
            % ContextMenuRequest property is passed through to ContextMenuPublisher 
            % to be published
            obj.ContextMenuPublisher.ContextMenuRequest = val;
        end
    end

end

