function removePeripheralAxes(this, Location)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if ~isempty(this.PeripheralAxes)
    % If there is atleast one peripheral axes grid:
    
    % Compare input location with location of peripheral axes
    % grids
    idx = strcmpi(Location, {this.PeripheralAxes(:).Location});
    
    % Return axes grid if located
    if any(idx)
        % Clean up listeners
        for ct = 1:numel(this.PeripheralAxes(idx).Listeners)
            delete(this.PeripheralAxes(idx).Listeners{ct});
        end
        % set title to axes grid if north peripheral axes is being removed
        if strcmpi(Location,'Top')
            this.AxesGrid.Title = this.PeripheralAxes(idx).AxesGrid.AxesGrid.Title;
            this.PeripheralAxes(idx).AxesGrid.AxesGrid.Title = '';
        end
        % Delete the axes grid
        delete(this.PeripheralAxes(idx).AxesGrid.AxesGrid);
        this.PeripheralAxes(idx) = [];
        
        % Reposition the axes
        layout(this);
    end
end
end
