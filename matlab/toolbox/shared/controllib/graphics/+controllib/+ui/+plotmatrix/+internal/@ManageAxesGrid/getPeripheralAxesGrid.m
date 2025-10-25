function PAx = getPeripheralAxesGrid(this, Location)
% getPeripheralAxesGrid - Get the ctrluis.axesgrid instance
% that represents the peripheral axes grid at a given location
%     Input: Location - Location at which the axexgrids are present
%                         (Top, Bottom, Right, Left)
%     Output:     PAx - AxesGrid at input Location

%   Copyright 2015-2020 The MathWorks, Inc.

PAx = [];
if ~isempty(this.PeripheralAxes)
    % If there is atleast one peripheral axes grid:
    
    % Compare input location with location of peripheral axes
    % grids
    idx = strcmpi(Location, {this.PeripheralAxes(:).Location});
    
    % Return axes grid if located
    if any(idx)
        AG = this.PeripheralAxes(idx).AxesGrid;
        PAx = AG.AxesGrid;
    end
end
end
