function resizePeripheralAxes(this, nr, nc, Location)
% Change the number of peripheral axes grid according to the
% number of axes in the core axes grid. Also set addition
% properties of the peripheral axes grid, such as tick mark
% locations

%   Copyright 2015-2020 The MathWorks, Inc.

resize(this, nr, nc);
a = this.AxesGrid.getaxes;
if strcmpi(Location, 'Top')
    for ct = 1:length(a)
        a(ct).XAxisLocation ='Top';
    end
elseif strcmpi(Location, 'Right')
    for ct = 1:length(a)
        a(ct).YAxisLocation ='Right';
    end
end
end
