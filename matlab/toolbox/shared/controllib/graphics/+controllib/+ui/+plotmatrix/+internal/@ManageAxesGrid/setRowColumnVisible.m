function setRowColumnVisible(this, AxesVisibility)
% SETROWCOLUMNVISIBLE
% Sets the row and column visibility of the axes grid.

%   Copyright 2015-2020 The MathWorks, Inc.

for ct = size(AxesVisibility,1):-1:1
    if all(strcmpi(AxesVisibility(ct,:), 'off'))
        this.AxesGrid.RowVisible{ct} = 'off';
    else
        this.AxesGrid.RowVisible{ct} = 'on';
    end
end

for ct = size(AxesVisibility,2):-1:1
    if all(strcmpi(AxesVisibility(:,ct), 'off'))
        this.AxesGrid.ColumnVisible{ct} = 'off';
    else
        this.AxesGrid.ColumnVisible{ct} = 'on';
    end
end
end
