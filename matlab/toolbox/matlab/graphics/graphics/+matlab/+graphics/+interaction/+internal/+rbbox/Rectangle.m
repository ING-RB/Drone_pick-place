classdef Rectangle < handle    
    % This is undocumented and will change in a future release 

    % Copyright 2020 The MathWorks, Inc.
    
    properties
        Thickness = 1
        Lines
        StartPoint
        EndPoint
        Visible = false
        StepSize = 1
        Position
        InitialPosition
    end
    
    methods
        function this = Rectangle(f, initRect)
            for i = 1:4
                temp(i) = matlab.graphics.interaction.internal.rbbox.Line(f);
            end
            this.Lines = temp;
            
            if (nargin == 2)
                this.setInitialPosition(initRect);
            end
        end
        
        function delete(this)
            for i = 1:4
                this.Lines(i).delete();
            end
        end
        
        function setStartPoint(this, point)
            this.StartPoint = point;
        end
        
        function point = getStartPoint(this)
            point = this.StartPoint;
        end
        
        function setStepSize(this, step)
            this.StepSize = step;
        end
        
        function setInitialPosition(this, initRect)
            this.InitialPosition = initRect;
            this.setStartPoint([initRect(1) initRect(2)]);
            this.Position = initRect;
            this.reset();
        end
        
        function rect = getInitialPosition(this)
            rect = this.InitialPosition;
        end
        
        function reset(this)
            % Resets the rectangle's positions to InitialPosition
            sp = this.StartPoint;
            wh = [this.InitialPosition(3) this.InitialPosition(4)];
            ep = sp + wh;
            this.Position = this.InitialPosition;
            this.setStartPoint(sp);
            this.setEndPoint(ep);
        end
        
        function show(this)
            for i = 1:4
                this.Lines(i).show();
            end
            this.Visible = true;
        end
        
        function hide(this)
            for i = 1:4
                this.Lines(i).hide();
            end
            this.Visible = false;
        end
        
        function newDimensions = applyStepSize(this, wh)
            remainder = mod(wh, this.StepSize);
            newDimensions = wh - remainder;
        end
        
        function wh = calculateWidthAndHeight(this, currentPoint)
            wh = currentPoint - this.StartPoint;
            wh = this.applyStepSize(wh);
        end

        function setEndPoint(this, point)
            this.EndPoint = point;
        end
        
        function point = getRectangleEndPoint(this, wh)
            % Returns the point in the rectangle diagonally opposite to the
            % start point based on the width and height
            point = this.StartPoint + wh;
        end
        
        function setPosition(this, endPoint)
            lower_left = min(this.StartPoint, endPoint);
            upper_right = max(this.StartPoint, endPoint);
            
            wh = upper_right - lower_left;
            w = wh(1);
            h = wh(2);
            
            pos = [lower_left(1) lower_left(2) w h];
            this.Position = pos;
        end
        
        function pos = getPosition(this)
            pos = this.Position;
        end
        
        function update(this, current_point)
            wh = this.calculateWidthAndHeight(current_point);
            this.setEndPoint(this.StartPoint + wh);
            this.setPosition(this.EndPoint);
            this.draw();
        end
        
        function draw(this)
            % Get the lower left and upper right points of the rectangle
            lower_left = min(this.StartPoint, this.EndPoint);
            upper_right = max(this.StartPoint, this.EndPoint);
            
            % Width and height of rectangle
            wh = upper_right - lower_left;
            w = wh(1);
            h = wh(2);
            
            % Bottom horizontal line
            this.Lines(1).setPosition([lower_left(1) ... 
                                       lower_left(2) ...
                                       w ... 
                                       this.Thickness]);
            % Upper horizontal line
            this.Lines(2).setPosition([lower_left(1) ...
                                       lower_left(2)+h ... 
                                       w ... 
                                       this.Thickness]);
            
            % Left vertical line
            this.Lines(3).setPosition([lower_left(1) ...
                                       lower_left(2) ...
                                       this.Thickness ...
                                       h]);
                                   
            % Right vertical line
            this.Lines(4).setPosition([lower_left(1)+w-this.Thickness...
                                       lower_left(2) ...
                                       this.Thickness ...
                                       h]) 
        end
    end
end

