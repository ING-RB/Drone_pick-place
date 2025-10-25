classdef HelpPanel < matlabshared.mediator.internal.Publisher & ...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    % HelpPanel - Hardware Manager visual module that can show
    % a help page given a mapFile and topicID in a panel that wraps a browser.

    % Copyright 2018-2023 The MathWorks, Inc.

    properties (Access = {?matlab.unittest.TestCase})
        % DOCUMENT - Handle to a appcontainer document for help panel
        Document matlab.ui.container.internal.appcontainer.Document

        % GRID - Handle to uigridlayout inside uifigure in document
        Grid

        % UIHTML - Handle to uihtml widget in Grid
        Uihtml
    end

    methods (Static)
        
        function out = getPropsAndCallbacks()
            out = ... % Property to listen to         % Callback function
                [ "AddDeviceHelpDocumentReady"          "handleAddDeviceHelpDocumentReady"; ...
                ];
        end
        
    end


    methods

        % Constructor
        function obj = HelpPanel(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj, src, evt)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);
        end

        % %%%%%%%%%% CALLBACKS %%%%%%%%%%% %

        function handleAddDeviceHelpDocumentReady(obj, args)
            obj.Document = args.Document;
            obj.Grid = uigridlayout(obj.Document.Figure, [1, 1], ...
                "BackgroundColor", 'white', ...
                "Padding", [0, 0, 0, 0]);
            obj.Uihtml = uihtml(obj.Grid);

            % Load the page
            obj.displayPage(args.Descriptor.getMapFile(), args.Descriptor.getTopicID());
        end

        % %%%%%%%%%% END CALLBACKS %%%%%%% %

    end

    methods (Access = private)

        % Method to display the help page given the MAPFILE and TOPICID
        function displayPage(obj, mapFile, topicID)

            if strcmp(mapFile, "") || strcmp(topicID, "")
                obj.Uihtml.HTMLSource = message("hwmanagerapp:hwmgrshared:MissingMapFileAndTopicID").getString();
                return
            end

            pageUrl = matlab.hwmgr.internal.util.getHelpTopicUrl(mapFile, topicID);
            if isempty(pageUrl)
                obj.Uihtml.HTMLSource = message("hwmanagerapp:hwmgrshared:TopicNotFound", topicID, mapFile).getString();
            else
                obj.Uihtml.HTMLSource = pageUrl;
            end
        end

    end

end

% LocalWords:  ROOTCONTAINER JAVAHELPPANEL mlwidgets MAINPANEL MAPFILE TOPICID
% LocalWords:  HELPPANEL
