classdef methodsViewTable < handle
%methodsViewTable Lightweight UI for viewing the methods of a class
%
% methodsViewTable is a helper function for methodsview and should not be
% called directly.  

% This function is unsupported and might change or be removed without notice
% in a future version.

%   Copyright 2019-2020 The MathWorks, Inc.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure    matlab.ui.Figure
        GridLayout  matlab.ui.container.GridLayout
        UITable     matlab.ui.control.Table
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, qcls, d, hdrs, colwidth, totwidth, numrows)
            % verification of classname is done in methodsview.m
            app.UIFigure.Name = char(qcls);
            app.UIFigure.Position(3) = app.UIFigure.Position(1) + totwidth;
            
            app.UIFigure.Position(4) = app.UIFigure.Position(2) + ( min(numrows, 16) * numrows);
            
            %app.UIFigure.Position(4) = app.UIFigure.Position(2) + (16 * numrows);
            app.GridLayout.Padding = [0 0 0 0];
            app.UITable.ColumnName = hdrs;
            app.UITable.Data = d;
            colwidth(end) = {'auto'};
            app.UITable.ColumnWidth = colwidth;
            addStyle(app.UITable, uistyle('FontWeight', 'bold'), 'column', 1);
            %app.UITable.BackgroundColor = [1 1 1; 0.96 0.96 0.96];
            app.UIFigure.Visible = 'on';
            
            %% when these gets implemented, uncomment these lines
            %app.UITable.RearrangeableColumns = true;
            %app.UITable.SelectionType = row;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.CloseRequestFcn = @app.closeFigure;
            
            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x'};

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {''};
            app.UITable.ColumnSortable = true;
            app.UITable.RowName = {};
            app.UITable.Layout.Row = 1;
            app.UITable.Layout.Column = 1;

            % Show the figure after all components are created
            %app.UIFigure.Visible = 'on';
        end
        
        function closeFigure(app, ~, ~)
            delete(app);
        end

    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = methodsViewTable(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Execute the startup function
            startupFcn(app, varargin{:});

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
