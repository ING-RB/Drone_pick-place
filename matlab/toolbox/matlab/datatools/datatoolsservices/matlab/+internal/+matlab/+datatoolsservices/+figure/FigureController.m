classdef FigureController < internal.matlab.datatoolsservices.figure.FigureView
    
    % Copyright 2021-2024 The MathWorks, Inc.

    properties(Access='private')
        FigureMouseUpListener;
        FigureMouseDownListener;
        FigureMouseMoveListener;
        FigureMouseEnterListener
        FigureMouseLeaveListener
        FigureKeyUpListener;
        FigureBlurListener;
    end
    
    methods

        function this = FigureController()
            this.setupFigureMouseUpListener();
        end
        
        function setupFigureMouseUpListener(this)
            this.FigureMouseUpListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremouseup'], @(msg)this.handleFigureMouseUp(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureMouseDownListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremousedown'], @(msg)this.handleFigureMouseDown(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureMouseMoveListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremousemove'], @(msg)this.handleFigureMouseMove(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureKeyUpListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figurekeyup'], @(msg)this.handleFigureKeyUp(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureMouseEnterListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/mouseenter'], @(msg)this.handleFigureMouseEnter(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureMouseLeaveListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/mouseleave'], @(msg)this.handleFigureMouseLeave(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            this.FigureBlurListener = message.subscribe(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/blur'], @(msg)this.handleFigureBlur(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end
        
        function handleFigureMouseUp(this, msg)
            message.publish(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremouseup/hitPosition'], this.getClientMouseEventData(msg));
        end

        function sendFigureUpdate(this, reply)
            message.publish(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figureupdate'], reply);
        end
        
        function handleFigureMouseDown(this, msg)
            message.publish(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremousedown/hitPosition'], this.getClientMouseEventData(msg));
        end
        
        function handleFigureMouseMove(this, msg)
            message.publish(['/DesktopDataTools/FigureView/' this.EmbeddedFigureID '/figuremousemove/hitPosition'], this.getClientMouseEventData(msg));
        end       
        
        function clientEventData = getClientMouseEventData(this, msg)
            hitPos = this.getHitPosition(msg);
            clientEventData = struct('hitPosition', hitPos);
        end
        
        function handleFigureBlur(this, msg)
        end
        
        function handleFigureKeyUp(this, msg)            
        end
        
        function handleFigureMouseEnter(this, msg)
        end
        
        function handleFigureMouseLeave(this, msg)
        end
        
        function [hitPosition, pixelPosition] = getHitPosition(this, msg)
            figPos = getpixelposition(this.EmbeddedFigure);
            xPos = msg.percentageX * figPos(3);
            yPos = msg.percentageY * figPos(4);
            pixelPosition = [xPos yPos];
            hitPosition = matlab.graphics.chart.internal.convertViewerCoordsToDataSpaceCoords(this.EmbeddedAxes, pixelPosition)';
        end

        function delete(this)
            
            if ~isempty(this.FigureMouseUpListener)
                message.unsubscribe(this.FigureMouseUpListener);
            end
            if ~isempty(this.FigureMouseDownListener)
                message.unsubscribe(this.FigureMouseDownListener);
            end
            if ~isempty(this.FigureMouseMoveListener)
                message.unsubscribe(this.FigureMouseMoveListener);
            end
            if ~isempty(this.FigureMouseLeaveListener)
                message.unsubscribe(this.FigureMouseLeaveListener);
            end
            if ~isempty(this.FigureMouseEnterListener)
                message.unsubscribe(this.FigureMouseEnterListener);
            end
            if ~isempty(this.FigureKeyUpListener)
                message.unsubscribe(this.FigureKeyUpListener);
            end
            if ~isempty(this.FigureBlurListener) 
                message.unsubscribe(this.FigureBlurListener);
            end
        end
    end
end

