classdef DocumentPane < matlabshared.mediator.internal.Publisher &...
                        matlabshared.mediator.internal.Subscriber & ...
                        matlab.hwmgr.internal.MessageLogger
    %DOCUMENTPANE - This module is responsible for managing the main
    %uipanel inside a figure document, that is provided to downstream teams
    %to place their applet widgets inside. This class was formerly known as
    %the RootPane module.
    
    %   Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Constant)
        % Message label properties for the root panec
        RootPaneMsgLabelWidth = 1;
        RootPaneMsgLabelHeight = 0.05;
        RootPaneMsgLabelFontSize = 12;
        RootPaneMsgLabelFontWeight = 'bold';
        RootPaneMsgLabelUnits = 'normalized';
    end
    
    properties(SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.DocumentPane');
        NewClientPanelReady
    end
    
    properties(Access = private)
        %ROOTCONTAINER - The container within the Hardware Manager that
        %represents the canvas for the Root Pane
        RootContainer
        
        % Handle to gridlayout inside the figure
        RootGrid matlab.ui.container.GridLayout
        
        % Handle to App Failure message shown in the root pane
        AppFailureLabel
        
        % Handle to the non enumerable device configuration  message in the
        % root pane
        NonEnumDevConfigLabel
        
        % Handle to the Java component JLabel for the help text
        HelpTextJLabel
        
        % Handle to the HG container of the JLabel for the help text
        HelpTextJContainer
        
        % Handle to app container document tab for the root pane
        % TODO: change to  matlab.ui.internal.FigureDocument after it is
        % enabled by app container team
        DocumentHandle matlab.ui.container.internal.appcontainer.Document
        
        % Handle to the ui widget to show help text in figure of document
        HelpText
    end
    
    methods (Static)
        function out = getPropsAndCallbacks()
           out =  ... % Property to listen to         % Callback function
                ["NewFigDocReady"                   "handleNewFigDocReady"; ...
                 "ShowAppFailedMsg"                 "showAppFailedMsg"; ...
                 "AddDeviceFigDocReady"             "handleAddDeviceFigDocReady"; ...
                 "AddNoDevicesMsgToDoc"             "addNoDevicesMsgToDoc"; ...
                ];
        end
    end
    
    methods
        
        function obj = DocumentPane(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end
        
        function subscribeToMediatorProperties(obj, ~, ~)
             eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);
        end
        
        % %%%%%%%%%% CALLBACKS %%%%%%%%%%% % 
        function handleNewFigDocReady(obj, document)
           clientPanel = obj.newClientPanel(document);
           obj.logAndSet("NewClientPanelReady", clientPanel);
        end

        function showAppFailedMsg(obj, args)
            % Create the label and place it in the root pane
            labelString = message('hwmanagerapp:framework:AppFailureMsg', args.AppletName, args.DeviceName).getString();
            rootPane = obj.getMainPanelFromView(args.Document);
            obj.AppFailureLabel = obj.createRootPaneMsg(rootPane, labelString, 'AppErrorMsg');
        end

        function handleAddDeviceFigDocReady(obj, document)
            obj.addGridLayout(document);
            panel = obj.newClientPanel(document);
            labelString = message('hwmanagerapp:framework:NonEnumDevConfigMsg').getString();
            obj.NonEnumDevConfigLabel = obj.createRootPaneMsg(panel, labelString, 'NonEnumDevConfigMsg');
        end
        
        function addNoDevicesMsgToDoc(obj, args)
            document = args.Document;
            msgTag = args.MsgTag;
            
            obj.addGridLayout(document);
            mainPanel = obj.addPanelToDocGrid(document);
            
            switch msgTag
                case "DAQ"
                    msg = message('hwmanagerapp:framework:DAQHelpText');
                case "MODBUS"
                    msg = message('hwmanagerapp:framework:ModbusHelpText').getString();
                case "RASPI"
                    msg = message('hwmanagerapp:framework:RaspberryPiHelpText').getString();
                case "ARDUINO"
                    msg = message('MATLAB:arduinoio:general:ArduinoHelpText').getString();
                case "TCPCLIENT_APP"
                    msg = message("transportapp:tcpclientapp:TcpipExplorerHelpText").getString();
            end
            textTemplete = '<html><body style="font-size:%dpx">%s</body></html>';
            
            text = sprintf(textTemplete, 20, msg);
            helpTextGrid = uigridlayout(mainPanel);
            helpTextGrid.ColumnWidth = {'1x', '3x', '1x'};
            helpTextGrid.RowHeight = {'1x', '3x', '1x'};
            
            obj.HelpText = uihtml(helpTextGrid);
            obj.HelpText.Layout.Row = 2;
            obj.HelpText.Layout.Column = 2;
            obj.HelpText.HTMLSource = text;
        end
        
        % %%%%%%%%%% END CALLBACKS %%%%%%% %
                
    end
    
    methods (Access = private)
        function labelWidget = createRootPaneMsg(obj, rootPane, text, labelTag)
            % This method will create a label object in the root pane and
            % place and size it appropriately. The label text and tag are
            % provided as inputs to this method.
            
            % Create the label
            gridLayout = uigridlayout(rootPane, [1, 1]);
            labelWidget = uilabel(gridLayout);
            labelWidget.WordWrap = 'on';
            labelWidget.Text = text;
            labelWidget.Tag = labelTag;
            
            % Set the font weight and size
            labelWidget.FontWeight = obj.RootPaneMsgLabelFontWeight;
            labelWidget.FontSize = obj.RootPaneMsgLabelFontSize;
            
            % TODO: update fontsize in RootPaneMsgLabelFontSize
            % after JS transition
            labelWidget.FontSize = 20;
            labelWidget.HorizontalAlignment = 'center';
            labelWidget.VerticalAlignment = 'center';
        end
        
        function clientPanel = newClientPanel(obj, document)
            % Add the uigridlayout
            obj.addGridLayout(document);
            % Create the panel in the uigridlayout
            clientPanel = obj.addPanelToDocGrid(document);
        end

        function addGridLayout(obj, document)
            obj.RootGrid = uigridlayout(document.Figure, [1, 1]);
            obj.RootGrid.Padding = [0, 0, 0, 0];
        end
        
        function rootPane = getMainPanelFromView(obj, view)
            rootPane = [];
            gridLayout = view.Figure.Children;
            % Check if the grid layout has any children before indexing
            % into it in case the root pane does not exist. This check
            % is added to help when debugging root pane issues.
            if ~isempty(gridLayout.Children)
                rootPane = gridLayout.Children(1);
            end
        end
        
        function panel = addPanelToDocGrid(obj, document)
            % UI widget position unit is pixel only. We need to get the
            % size of the figure for the panel.
            grid = document.Figure.Children;
            panel = uipanel(grid, 'Tag', '_ROOTPANE');
        end        
    end
    
end

% LocalWords:  ROOTCONTAINER MAINPANEL GETHGVIEW HWM STARTINGPANEL GETWEBVIEW
% LocalWords:  HANDLEMESSAGEBUS evt hwmanagerapp ROOTPANE
