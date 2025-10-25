classdef JavaWrapperController < matlab.ui.internal.WebUIContainerController
    % JavaWrapperController Web-based controller for JavaComponent.
    
    % Copyright 2022 - 2023 The MathWorks, Inc.
    properties
        JFrame;
        JFrameHandle;
        JPanel;
        ChannelId;
        Subscription;
        CurrentImage;
        ParentFig;
        UpdateTimer;
    end
    
    methods
        % constructor
        function obj = JavaWrapperController(model, varargin)
            % Super constructor
            obj = obj@matlab.ui.internal.WebUIContainerController( model, varargin{:} );
            obj.createJavaDialog();

            % render the javacomponent when the view is ready
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenViewIsReady(obj.Model, @() obj.renderJavaComponent());
        end
        
        function className = getViewModelType(~, ~)
            className = 'matlab.ui.container.internal.JavaWrapper';
        end

        function delete(obj)
            if ~isempty(obj.UpdateTimer)
                stop(obj.UpdateTimer);
            end
            delete(obj.UpdateTimer);
            obj.JFrame.dispose();
            message.unsubscribe(obj.Subscription);
        end
    end
    
    methods(Access=private)
        function createJavaDialog(obj)
            % Create a JDialog and add the javacomponent.
            hgProxy = obj.Model;
            obj.ParentFig = ancestor(hgProxy,'figure');
            
            % Render in pop-out window.
            jf = javaObjectEDT(javax.swing.JDialog());
            jf.setTitle('JavaComponent');
            jf.setDefaultCloseOperation(jf.HIDE_ON_CLOSE);
            jf.setAlwaysOnTop(true);
            jf.setResizable(false);
                     
            jp = javaObjectEDT(javaMethodEDT('getContentPane', jf));
            pos = getpixelposition(hgProxy);
            jp.setPreferredSize(java.awt.Dimension(obj.scale(pos(3)),obj.scale(pos(4))));
            jp.add(hgProxy.JavaPeer);
            
            obj.JFrame = jf;
            obj.JFrameHandle = handle(jf,'callbackproperties');
            obj.JPanel = jp;
            
            setappdata(hgProxy,'Popout',obj);
        end

        function renderJavaComponent(obj)
            obj.initialize();
            obj.addListeners();
            obj.setJavaDialogSize();
            obj.refreshImage();
            obj.startTimer();
        end

        function startTimer(obj)
            % The javacomponent image at client is updated using a timer every 0.5 sec
            obj.UpdateTimer = timer('TimerFcn', @(o, e) obj.refreshImage(), ...
                'Period', .5, 'ExecutionMode', 'fixedSpacing', ...
                'BusyMode', 'drop', 'StartDelay', 5, ...
                'Name', char(obj.Model.JavaPeer.getClass.getName));
            start(obj.UpdateTimer);
        end

        function initialize(obj)
            hgProxy = obj.Model;

            % subscribe to the message channel.
            obj.ChannelId = ['/gbt/javaWrapper/' hgProxy.getId()];
            obj.Subscription = message.subscribe(obj.ChannelId,@(msg) obj.handleMessage(msg));
            
            % Show frameless or not?
            if isappdata(hgProxy,'ShowTitleBar') || strcmpi(obj.ParentFig.WindowStyle,'docked')
                obj.JFrame.setUndecorated(false);
            else 
                obj.JFrame.setUndecorated(true);
            end
        end

        function addListeners(obj)
            hgProxy = obj.Model;

            % Setup listener to update view when size of JavaComponent wrapper changes.
            addlistener(hgProxy,'SizeChanged',@(o,e) obj.handleResize());
            
            % Hide on certain interactions.
            addlistener(obj.ParentFig,'LocationChanged',@(o,e) obj.hideFrame());
            addlistener(obj.ParentFig,'SizeChanged',@(o,e) obj.hideFrame());
            addlistener(obj.ParentFig,'WindowMousePress',@(o,e) obj.hideFrame());
            obj.JFrameHandle.WindowLostFocusCallback = @(o,e) obj.hideFrame();
            obj.JFrameHandle.WindowDeactivatedCallback = @(o,e) obj.hideFrame();
        end

        function handleResize(obj)
            obj.setJavaDialogSize();
            obj.refreshImage();
        end

        function setJavaDialogSize(obj)
            % set the size of the JDialog
            hgProxy = obj.Model;

            % Sizing
            pos = getpixelposition(hgProxy,true);
            obj.JPanel.setPreferredSize(java.awt.Dimension(obj.scale(pos(3)),obj.scale(pos(4))));
            jcomp = hgProxy.JavaPeer;
            jcomp.setSize(pos(3),pos(4));
            obj.JFrame.pack();
            
            % Location            
            if strcmpi(obj.ParentFig.WindowStyle,'docked')
                obj.JFrameHandle.setLocationRelativeTo([]);
            else
                figPos = getpixelposition(obj.ParentFig,true);
                scrSize = get(0,'ScreenSize');
                SH = scrSize(4);
                FX = figPos(1);
                FY = figPos(2);
                CX = pos(1);
                CY = pos(2);
                CH = pos(4);
                IN = obj.JFrameHandle.getInsets();
                
                obj.JFrameHandle.setLocation(obj.scale(FX+CX-(IN.left)-2), obj.scale(SH-FY-CY-CH-(IN.top)+2));
            end
        end

        function refreshImage(obj)
            % Generate a base64 URI of the javacomponent and publish to client.
            byteArray = com.mathworks.hg.util.ImageUtils.getImageBytes(obj.JFrame.getContentPane());
            iconString = sprintf('data:image/%s;base64,%s','jpg', matlab.net.base64encode(byteArray));

            if ~strcmp(iconString, obj.CurrentImage)
                obj.CurrentImage = iconString;
                message.publish(obj.ChannelId, obj.CurrentImage);
            end
        end

        function handleMessage(obj, msg)
            % Handle messages from client.
            if strcmp(msg, "Show")
                % When the message is show, 
                % the JDialog containing the javacomponent is made visible.
                % The how message is sent from the client when the user hover over a javacomponent.
                obj.setJavaDialogSize();
                obj.showFrame();
            end
        end
        
        function showFrame(obj)
            % Make the JDialog containing the javacomponent visible.
            obj.JFrame.show();
            obj.JFrame.requestFocusInWindow();
        end
        
        function hideFrame(obj)
            % Hide the JDialog containing the javacomponent
            if isvalid(obj) && obj.JFrame.isShowing
                obj.refreshImage();
                obj.JFrame.hide();
            end
        end       
    end
    
    methods (Static)
        function out = scale (in)
            % For scaling on Windows/Linux HiDPI
            out = com.mathworks.util.ResolutionUtils.scaleSize(in);
        end
    end
end
