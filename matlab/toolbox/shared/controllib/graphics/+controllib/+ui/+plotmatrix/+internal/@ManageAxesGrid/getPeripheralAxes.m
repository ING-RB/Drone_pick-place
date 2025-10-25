function PAx = getPeripheralAxes(this, Location)
% getPeripheralAxes - Get the ManagePeripheralAxesGrid instance
% that represents the peripheral axes grid at a given location
%     Input: Location - Location at which the axexgrids are present
%                         (Top, Bottom, Right, Left)
%     Output:     PAx - AxesGrid at input Location

%   Copyright 2015-2020 The MathWorks, Inc.

if isempty(this.PeripheralAxes)
    % Add new peripheral axes
    addPeripheralAxes(this, Location);
    % Return added axes grid
    PAx = getaxes(this.PeripheralAxes(end).AxesGrid.AxesGrid);
else
    % If there is atleast one peripheral axes grid:
    
    % Compare input location with location of peripheral axes
    % grids
    [bool, idx] = ismember(Location, {this.PeripheralAxes(:).Location});
    
    % Return axes grid if located
    if bool
        PAx = getaxes(this.PeripheralAxes(idx).AxesGrid.AxesGrid);
    else
        % Add new peripheral axes
        addPeripheralAxes(this, Location);
        % Return added axes grid
        PAx =  getaxes(this.PeripheralAxes(end).AxesGrid.AxesGrid);
    end
end
end
