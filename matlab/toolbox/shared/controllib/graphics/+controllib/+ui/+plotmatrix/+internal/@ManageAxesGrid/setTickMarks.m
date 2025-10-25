function setTickMarks(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

% Due to the behavior of ctrluis.axesgrid, Xtick marks are
% placed on the left most column and YTick marks are placed on
% the bottom most row. Additionally, XTick marks have to be
% placed on the right most column, if peripheral axes are
% present at location 'Right'. YTick marks have to be placed on
% the top most row, if peripheral axes are present at location
% 'Top'.
VisAxes = findvisible(this.AxesGrid);
EastPeripheral = getPeripheralAxesGrid(this, 'Right');
NorthPeripheral = getPeripheralAxesGrid(this, 'Top');

if ~isempty(VisAxes)
    [nR,nC] = size(VisAxes);
    if isempty(NorthPeripheral)
        % No peripheral axes - no rulers needed
        for ct = 1:numel(this.Ruler.Top)
            if isvalid(this.Ruler.Top(ct))
                this.Ruler.Top(ct).Parent = [];
            end
        end
    else
        % Peripheral axes along top
        if numel(this.Ruler.Top) < nC
            % Create additional rulers as needed
            for ct = numel(this.Ruler.Top)+1:nC
                this.Ruler.Top(ct) = matlab.graphics.axis.decorator.NumericRuler;
                set(this.Ruler.Top(ct), 'FirstCrossOverValue',  Inf);
                set(this.Ruler.Top(ct), 'Axis', 0);
                set(this.Ruler.Top(ct).Axle, 'AlignVertexCenters', 'On');
                set(this.Ruler.Top(ct).Axle, 'LineWidth', 0.75);
                set(this.Ruler.Top(ct), 'LineWidth', 0.75);
                set(this.Ruler.Top(ct), 'TickDir', 'In');
            end
        else
            % Un-parent additional rulers
            nTop =numel(this.Ruler.Top);
            for ct = nTop:-1:nC
                if isvalid(this.Ruler.Top(ct))
                    this.Ruler.Top(ct).Parent = [];
                else
                    this.Ruler.Top(ct) = [];
                end
            end
        end
        
        % Parent all rulers to appropriate axes and set axes box to off
        for ct = 1:nC
            this.Ruler.Top(ct).Parent = get(VisAxes(1,ct), 'DataSpace');
        end
    end
    
    if isempty(EastPeripheral)
        % No peripheral axes - no rulers needed
        for ct = 1:numel(this.Ruler.Right)
            this.Ruler.Right(ct).Parent = [];
        end
    else
        nRight = numel(this.Ruler.Right);
        % Delete invalid rulers
        for ct = nRight:-1:1
            if ~isvalid(this.Ruler.Right(ct))
                this.Ruler.Right(ct) = [];
            end
        end
        % Peripheral axes along right
        if numel(this.Ruler.Right) < nR
            % Create additional rulers as needed
            for ct = numel(this.Ruler.Right)+1:nR
                this.Ruler.Right(ct) = matlab.graphics.axis.decorator.NumericRuler;
                set(this.Ruler.Right(ct), 'FirstCrossOverValue',  Inf);
                set(this.Ruler.Right(ct), 'Axis', 1);
                set(this.Ruler.Right(ct).Axle, 'AlignVertexCenters', 'On');
                set(this.Ruler.Right(ct).Axle, 'LineWidth', 0.75);
                set(this.Ruler.Right(ct), 'LineWidth', 0.75);
                set(this.Ruler.Right(ct), 'TickDir', 'In');
            end
        else
            
            % Un-parent additional rulers
            for ct = nRight:-1:nR
                if isvalid(this.Ruler.Right(ct))
                    this.Ruler.Right(ct).Parent = [];
                else
                    this.Ruler.Right(ct) = [];
                end
            end
        end
        
        % Parent all rulers to appropriate axes
        for ct = 1:nR
            if isvalid(this.Ruler.Right(ct))
                this.Ruler.Right(ct).Parent = get(VisAxes(ct,end), 'DataSpace');
            else
                this.Ruler.Right(ct) = [];
            end
        end
    end
end
end
