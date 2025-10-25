classdef ViewerBookmark < handle
    %This class is for internal use only. It may be removed in the future.

    %ViewerBookmark Rosbag topic contents UI for the Rosbag Viewer app
    %   Bookmark = ros.internal.ViewerBookmark(APPCONTAINER)
    %      Create the RosbagViewer topic list in the provided app container.
    %      Each topic will be expandable to see which fields are contained
    %      within that topic's messages.

    %   Copyright 2023 The MathWorks, Inc.

    % UI objects
    properties 
        % Figure panel containing all topic details
        BookmarkPanel
        GridLayout
        TableHandle
        BookmarkTable
        ElapseTimeFormat = true;

        AppContainerWeakHndl
    end

    properties % Access will be restricted to Presenter/tests, when created
        % Activate on timeline slider new position
        TableCellEditCallback = function_handle.empty
        TableSelectionChangedFcn = function_handle.empty
        TableCellSelectionCallback  = function_handle.empty
        TableClickedFcn = function_handle.empty
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        TagBookmarkPanel = 'RosbagViewerBookmarkPanel'
        DeleteIcon = fullfile(matlabroot, 'toolbox', 'ros', ...
            'visualizationapp', 'resources', 'icons', 'removeLine.svg');
    end

    methods
        function setAppMode(obj,appMode)
            appContainer = obj.AppContainerWeakHndl.get;
            if appMode == ros.internal.ViewerPresenter.RosbagVisualization
                if isempty(obj.BookmarkPanel) || ~isvalid(obj.BookmarkPanel)
                    buildBookmarkPanel(obj);
                    add(appContainer, obj.BookmarkPanel);
                end
            elseif ~isempty(obj.BookmarkPanel) && isvalid(obj.BookmarkPanel)
                removePanel(appContainer, obj.BookmarkPanel.Tag);
            end
        end

        function obj = ViewerBookmark(appContainer, tableData)
            %ViewerBookmark Construct the bookmark panel
            
            %Store a weak handle of the app container
            obj.AppContainerWeakHndl = matlab.internal.WeakHandle(appContainer);
        end

        function set.TableCellEditCallback(obj, val)
            obj.TableCellEditCallback = validateCallback(val, "TableCellEditCallback");
        end

        function set.TableSelectionChangedFcn(obj, val)
            obj.TableSelectionChangedFcn = validateCallback(val, "TableSelectionChangedFcn");
        end

        function set.TableCellSelectionCallback(obj, val)
            obj.TableCellSelectionCallback = validateCallback(val, "TableCellSelectionCallback");
        end

        function set.TableClickedFcn(obj, val)
            obj.TableClickedFcn = validateCallback(val, "TableClickedFcn");
        end

        function updateBookmarkTable(obj, data)
            obj.TableHandle.Data = data;
        end

        function resetBookmarkTable(obj)
            %reset to default

            obj.TableHandle.Data = [];
            obj.TableHandle.Visible = matlab.lang.OnOffSwitchState.off;
        end

        function showBookmarkTable(obj)
            %showBookmarkTable make bookmark table visible in bookmark
            %panel
            if ~isempty(obj.TableHandle.Data)
                obj.TableHandle.Visible = matlab.lang.OnOffSwitchState.on;
            end
        end

        function setElapseTimeFormat(obj, val)
            % Set ElapseTimeFormat property to define if the bookmark start
            % time is ElapseTimeFormat format if true and ElapseTimeForm is
            % false if timestamp
            obj.ElapseTimeFormat = val;
        end

        function val = getElapseTimeFormat(obj)
            % Set ElapseTimeFormat property to define if the bookmark start
            % time is ElapseTimeFormat format if true and ElapseTimeForm is
            % false if timestamp
            val = obj.ElapseTimeFormat;
        end
    end

    methods (Access = protected)

        function buildBookmarkPanel(obj)
            %buildBookmarkPanel Create topic panel and initialize contents

            % Add the topic tree panel to the left
            panelOptions = struct("Title", getString(message("ros:visualizationapp:view:BookmarkLabel")), ...
                                  "Region", "right" );
            obj.BookmarkPanel = matlab.ui.internal.FigurePanel(panelOptions);
            windowbounds = ros.internal.utils.getWindowBounds;
            obj.BookmarkPanel.PreferredWidth = windowbounds(3)/4.5;
            obj.BookmarkPanel.Tag = obj.TagBookmarkPanel;
            
            % Setup grid layout
            obj.GridLayout = uigridlayout(obj.BookmarkPanel.Figure, [1 1]);
            obj.GridLayout.RowHeight = {'fit'};
            obj.GridLayout.ColumnWidth = {'fit'};
            obj.GridLayout.Padding = [0 0 0 0];
            obj.GridLayout.Scrollable = 'on';

            obj.BookmarkTable = table();
            obj.TableHandle = uitable(obj.GridLayout);
            tableStyleForDelete = matlab.ui.style.internal.IconIDStyle('IconId', 'delete_bookmark');
            startimelabel = getString(message("ros:visualizationapp:view:StartTime"));
            durationlabel = getString(message("ros:visualizationapp:view:Duration"));
            labelbookmarklabel = getString(message("ros:visualizationapp:view:LabelBookmark"));
            %showontimeLinelabel = getString(message("ros:visualizationapp:view:ShowOnTimeLine"));
            deleteLabellabel = getString(message("ros:visualizationapp:view:DeleteLabel"));
            tabletooltip = getString(message("ros:visualizationapp:view:BookmarkTableTooltip"));

            obj.TableHandle.ColumnName = {labelbookmarklabel, ...
                startimelabel, durationlabel, ...showontimeLinelabel,
                deleteLabellabel };
            %DefaultRow = {'', '', '', false, ''}; uncomment this when new
            %slider is used
            DefaultRow = {'', '', '', ''};

            obj.TableHandle.Data = [];
            addStyle(obj.TableHandle, tableStyleForDelete, 'column', 4);
            obj.TableHandle.RowName = '';
            obj.TableHandle.ColumnSortable = [true, true, true, false];
            obj.TableHandle.ColumnEditable = [true true true false];
            obj.TableHandle.SelectionType = 'row';
            obj.TableHandle.Tooltip = tabletooltip;
            obj.TableHandle.Multiselect = 'off';
            obj.TableHandle.Layout.Row = 1;
            obj.TableHandle.Layout.Column = 1;
            obj.TableHandle.CellEditCallback = ...
                @(source, event) makeCallback(obj.TableCellEditCallback, source, event);
            obj.TableHandle.Visible = matlab.lang.OnOffSwitchState.off;
            % row selection callback
            obj.TableHandle.SelectionChangedFcn = @(source, event) makeCallback(obj.TableSelectionChangedFcn, source, event);
            obj.TableHandle.CellSelectionCallback = @(source, event) makeCallback(obj.TableCellSelectionCallback, source, event);
            obj.TableHandle.CellEditCallback =@(source, event) makeCallback(obj.TableCellEditCallback, source, event);
            obj.TableHandle.ClickedFcn =@(source, event) makeCallback(obj.TableClickedFcn, source, event);
        end
    end
end % END of Class

%% Helper functions that have no need for class access

function makeCallback(fcn, varargin)
%makeCallback Evaluate specified function with arguments if not empty

if ~isempty(fcn)
    feval(fcn, varargin{:})
end
end

function fHandle = validateCallback(fHandle, propertyName)
%validateCallback Ensure callback has correct type

% Accept any empty type to indicate no callback
if isempty(fHandle)
    fHandle = function_handle.empty;
else
    validateattributes(fHandle, ...
        "function_handle", ...
        "scalar", ...
        "ViewerBookmark", ...
        propertyName)
end
end