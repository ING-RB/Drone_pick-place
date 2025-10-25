function editChars(this,parent)
%EDITCHARS  Builds group box for editing Characteristics.

%   Copyright 1986-2020 The MathWorks, Inc.

gridLayout = uigridlayout(parent,[1 1]);
gridLayout.RowHeight = {'fit'};
this.NoOptionsLabel = uilabel(gridLayout,'Text',getString(message('Controllib:gui:strNoOptionsForSelectedPlot')));

end