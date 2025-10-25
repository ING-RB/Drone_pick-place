clear;
divfigureNum = 4;

f = matlab.ui.internal.divfigure;
f.Position(3) = 1000;

g = uigridlayout(f, [divfigureNum 2]);
g.Scrollable = 'on';
g.RowHeight = repmat(400, 1, divfigureNum);
g.ColumnWidth = {'4x', '1x'};

% Dummy data
tableName = 'Statistics';
rowNames = ["Type", "Row 2", "Row 3"];
rowVals = ["double", "Value 2", "Value 3"];

for i = 1:divfigureNum
    % Figure
    x = 0:100;
    y = randi([1 50], 1, 101);
    ax = axes(g);
    plot(ax, x, y);

    % Summary Table
    summaryGrid = uigridlayout(g, [4 2]);
    summaryGrid.RowHeight = {'fit', 'fit', 'fit', 'fit'};
    summaryGrid.RowSpacing = 1;
    uilabel(summaryGrid, 'Text', tableName);
    uilabel(summaryGrid, 'Text', '');
    for j = 1:3
        uilabel(summaryGrid, 'Text', rowNames(j));
        uilabel(summaryGrid, 'Text', rowVals(j));
    end
end

divFigurePacket = matlab.ui.internal.FigureServices.getDivFigurePacket(f);
