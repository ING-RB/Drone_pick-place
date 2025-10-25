function addAxes_(this, NumRows, NumColumns)
%

%   Copyright 2015-2020 The MathWorks, Inc.

% Get the axes
Axes = this.AxesGrid.getaxes;

% Get the current number of rows and columns
CurrNumRows = size(Axes,1);
CurrNumColumns = size(Axes,2);

NewRows = CurrNumRows+NumRows;
NewColumns = CurrNumColumns+NumColumns;

if NewRows < 0 || NewColumns < 0
    error(message('Controllib:general:UnexpectedError', ...
        'Number of rows and columns should be a positive scalar integer'));
else
    resize_(this, CurrNumRows+NumRows, CurrNumColumns+NumColumns);
end
end
