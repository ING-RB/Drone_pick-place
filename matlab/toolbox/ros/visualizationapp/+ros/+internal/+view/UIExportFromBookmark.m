classdef UIExportFromBookmark < handle
%This class is for internal use only. It may be removed in the future.

    %UIExportFromTopic App is used to create the app for exporting messages
    %to new bag file based on selected bookmarks
    %   uiapphndl = ros.internal.view.UIExportFromBookmark(bookmarkTable, rosVersion)
    %   uiapphndl.showApp()

    %   Copyright 2024 The MathWorks, Inc.
    
    % UI Objects
    properties
        % Main Figure
            FigureHandle
            MainGridObj 
            
            DescriptionLabelObj
            SelectLabelObj 
            BmTableObj
            
            StorageTypeDropDownObj 
            SubGrid
            
            CancelButton
            ExportButton
    end
    
    properties (Constant, Access = ?matlab.unittest.TestCase)
        % definition of all the tags for the widgets
        AppTag = 'ExportFromBookmarkUITag';
        AppMainGridTag = 'ExportFromBookmarkUIMainGridTag';
         
        
        DescriptionLabelTag = 'ExportFromBookmarkUIDescriptionTag';
        SelectLabelTag = 'ExportFromBookmarkUISelectTag';
        BmTableTag = 'ExportFromBookmarkUIBmTableTag';
        
        StorageTypeDropDownTag = 'ExportFromBookmarkUIStorageTypeTag' 
        SubGridTag = 'ExportFromBookmarkUISubGridTag'; 
         
        CancelButtonTag = 'ExportFromBookmarkUICancelButtonTag';
        ExportButtonTag = 'ExportFromBookmarkUIExportButtonTag';

    end

    properties
        % Function callbacks
        ExportButtonClickedFcn = function_handle.empty;
    end

    methods
        function obj = UIExportFromBookmark(bmTable, rosVersion)
            obj.buildUI(bmTable, rosVersion);
        end

        function showApp(obj)
            obj.FigureHandle.Visible = matlab.lang.OnOffSwitchState.on;
        end

        function set.ExportButtonClickedFcn(obj, val)
            % setter to ExportButtonClickedFcn
            obj.ExportButtonClickedFcn = validateCallback(val, "ExportFromBookmarkUIExportButtonTag");
        end

        function closeApp(obj)
            close(obj.FigureHandle);
        end

        function intervals = getSelectedIntervals(obj)
            % getSelectedIntervals returns a n by 2 array of (StartTime,
            % EndTime) pairs that are selected in the UI.
            bmTable = obj.BmTableObj.Data;

            if isempty(bmTable)
                intervals = [];
                return;
            end

            starttimelabel = 'Starttime';
            durationlabel = 'Duration';

            % Leave only rows which have Choice set to true
            filteredTable = bmTable(bmTable.('Choice'), :);

            % Get a n by 2 matrix of (StartTime, EndTime) intervals
            intervals = [filteredTable.(starttimelabel) filteredTable.(durationlabel) + filteredTable.(starttimelabel)];
        end

        function [timeIntervals, topics] = getBagFilter(obj)
            %getBagFilter returns the time and topics based on which a bag
            %file will be filtered. The filters are selected by the user through the UI.
            %
            %    uiapphndl = UIExportFromBookmark(BmTable);
            %    [timeIntervals, topics] = uiapphndl.getBagFilter();
            %    bagSel = select(bag, Time=timeIntervals, topic=topics)
            
            timeIntervals = obj.getSelectedIntervals();
            
            if isempty(timeIntervals)
                error(message("ros:visualizationapp:view:ExportAppBookmarkNoSelect"))
            end

            % Since this UI only allows to select bookmarks.
            topics = [];
        end

        function storageFormat = getStorageFormat(obj)
            % getStorageFormat fetches the selected storage format.
            % ".bag" for ROS and ".bag" or ".mcap" for ROS2.

            storageFormat = obj.StorageTypeDropDownObj.Value;

        end

    end

    methods(Access=private)
        function buildUI(obj, bmTable, rosVersion)
            % Main Figure
            obj.FigureHandle = uifigure("Position", ...
                obj.getWindowSize,"Resize", matlab.lang.OnOffSwitchState.on, ...
                "Name", getString(message("ros:visualizationapp:view:ExportAppBookmarkWindowTitle")), ...
                "Tag", obj.AppTag, ...
                "Visible", "off", ...
                "WindowStyle", "modal");
            
            % Main Grid
            obj.MainGridObj = uigridlayout(obj.FigureHandle, ...
                "Tag", obj.AppMainGridTag);
            obj.MainGridObj.RowHeight = {'fit' 'fit' 'fit' 'fit'};
            obj.MainGridObj.ColumnWidth = {'fit'};
            
            % Description
            obj.DescriptionLabelObj = uilabel(obj.MainGridObj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppBookmarkDescription")), ...
                "FontSize", 16, ...
                "FontWeight", "bold", ...
                "Tag", obj.DescriptionLabelTag);
            % Select Label
            obj.SelectLabelObj = uilabel(obj.MainGridObj, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppBookmarkSelectLabel")), ...
                "Tag", obj.SelectLabelTag);
            
            % Table Object
            obj.BmTableObj = uitable(obj.MainGridObj, ...
                "Tag", obj.BmTableTag );
            startimelabel = getString(message("ros:visualizationapp:view:StartTime"));
            durationlabel = getString(message("ros:visualizationapp:view:Duration"));
            labelbookmarklabel = getString(message("ros:visualizationapp:view:LabelBookmark"));
            choicelabel = getString(message("ros:visualizationapp:view:ExportAppBookmarkTableChoiceLabel"));

            obj.BmTableObj.ColumnName = { choicelabel, labelbookmarklabel, ...
            startimelabel, durationlabel};

            if ~isempty(bmTable)      
                BmTable = bmTable(:, ...
                    {'Label', 'Starttime', 'Duration'});
                BmTable = addvars(BmTable, false(height(BmTable), 1), Before=1, ...
                    NewVariableNames='Choice');
            else
                BmTable = [];
            end
            
            obj.BmTableObj.Data = BmTable;
            obj.BmTableObj.ColumnEditable = [true false false false];
            obj.BmTableObj.ColumnSortable = [false true true true];
            obj.BmTableObj.SelectionType = 'row';

            obj.BmTableObj.CellEditCallback = @obj.singleSelectCallback;
            
            % StorageType selector
            obj.StorageTypeDropDownObj = uidropdown(obj.MainGridObj, ...
                "Tag", obj.StorageTypeDropDownTag);
            if isequal(rosVersion, "ROS")
                obj.StorageTypeDropDownObj.Items = ".bag";
            else
                % 
                obj.StorageTypeDropDownObj.Items = [".db3" ".mcap"];
            end
            
            % Sub grid
            obj.SubGrid = uigridlayout(obj.MainGridObj, ...
                "Tag", obj.SubGridTag);
            obj.SubGrid.RowHeight = {'fit'};
            obj.SubGrid.ColumnWidth = {'1x' '1x' '1x' '1x'};
            obj.SubGrid.Padding = [0 10 0 10];

            Hid1 = uilabel(obj.SubGrid, "Text", "");
            Hid1.Visible = matlab.lang.OnOffSwitchState.on;

            Hid2 = uilabel(obj.SubGrid, "Text", "");
            Hid2.Visible = matlab.lang.OnOffSwitchState.on;
            
            % Buttons to cancel and export
            obj.CancelButton = uibutton(obj.SubGrid, ...
                "Tag", obj.CancelButtonTag,...
                "Text", getString(message("ros:visualizationapp:view:ExportAppBookmarkCancelButtonLabel")));
            obj.ExportButton = uibutton(obj.SubGrid, ...
                "Tag",obj.ExportButtonTag, ...
                "Text", getString(message("ros:visualizationapp:view:ExportAppBookmarkExportButtonLabel")));

            obj.CancelButton.ButtonPushedFcn = @(src, event) obj.closeApp();
            obj.ExportButton.ButtonPushedFcn = @(src, event) obj.ExportButtonClickedFcn();
        end
    end

    methods(Access=private, Static)
        function singleSelectCallback(src, event)
            selectedRow = event.Indices(1);
            
            rowFilter = true(size(src.Data.Choice));
            rowFilter(selectedRow) = false;

            otherCells = src.Data.Choice(rowFilter);
            
            if any(otherCells)
                src.Data.Choice(selectedRow) = event.PreviousData;
            end
        end

        function bounds = getWindowSize()
            %getWindowSize get the target window size based on screen
            %resoultion. uifigure doesn't automatically resize based on
            %content.
            screenSize = get(groot, 'ScreenSize');
            if isequal(screenSize, [1 1 1920 1080]) % 1080p (HD) display
                bounds = (ros.internal.utils.getWindowBounds).*[2.5 2 0.35 0.6];
            else
                bounds = (ros.internal.utils.getWindowBounds).*[2.5 2 0.28 0.6];
            end

        end
    end
end


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
        propertyName)
end
end

% LocalWords:  uiapphndl Starttime mcap
