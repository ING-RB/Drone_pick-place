classdef UISearchRosbag < handle
    %This class is for internal use only. It may be removed in the future.

    %UISearchRosbag App is used to create the app for searching a rosbag
    %file. This class also have all the interaction methods required to use
    %this app.
    %   uiapphndl = ros.internal.view.UISearchRosbag()
    %   uiapphndl.showApp()

    %   Copyright 2024 The MathWorks, Inc.

    % UI objects
    properties
        % Figure panel and all the ui components

        FigureHandle
        MainGridLayout

        SearchFilterTitleObj

        TagSFMainPanelObj
        TagSFChildGridObj
        TagSFEditFieldObj
        TagSFListBoxObj

        BookmarkSFMainPanelObj
        BookmarkSFChildGridObj
        BookmarkSFEditFieldObj
        BookmarkSFListBoxObj

        VisualizerSFMainPanelObj
        VisualizerSFChildGridObj
        VisualizerSFEditFieldObj
        VisualizerSFListBoxObj

        TagSearchBoxHndl

        ResultPanelObj
        ResultMainGridObj
        ActiveFilterLabelObj

        TagLabelObj
        TagPanelObj
        TagGridObj
        BookmarkLabelObj
        BookmarkPanelObj
        BookmarkGridObj
        VisualizerLabelObj
        VisualizerPanelObj
        VisualizerGridObj
        SearchResultLabelObj
        ResultsTableObj
        ExportToCSVResultsAreaButtonObj

        ClearTagTextAreaButtonObj
        ClearBMTextAreaButtonObj
        ClearVisualizerTextAreaButtonObj
    end

    properties
        TagItemsOnLoad
        BMItemsOnLoad
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        % definition of all the tags for the widgets
        AppTag = 'SearchRosBagUITag';
        AppMainGridTag = 'SearchRosBagUIMainGridTag';

        SearchFilterTitleTag = 'SearchRosBagUITitleTag';

        TagSFMainPanelTag  = 'SearchRosBagTagSearchFilterPanelTag';
        TagSFChildGridTag  = 'SearchRosBagTagSearchFilterGridTag';
        TagSFEditFieldTag  = 'SearchRosBagTagSearchFilterEditFieldTag';
        TagSFListBoxTag  = 'SearchRosBagTagSearchFilterListBoxTag';

        BookmarkSFMainPanelTag  = 'SearchRosBagBMSearchFilterPanelTag';
        BookmarkSFChildGridTag  = 'SearchRosBagBMSearchFilterGridTag';
        BookmarkSFEditFieldTag  = 'SearchRosBagBMSearchFilterEditFieldTag';
        BookmarkSFListBoxTag  = 'SearchRosBagBMSearchFilterListBoxTag';


        VisualizerSFMainPanelTag  = 'SearchRosBagVisualizerSearchFilterPanelTag';
        VisualizerSFChildGridTag  = 'SearchRosBagVisualizerSearchFilterGridTag';
        VisualizerSFEditFieldTag  = 'SearchRosBagVisualizerSearchFilterEditFieldTag';
        VisualizerSFListBoxTag    = 'SearchRosBagVisualizerSearchFilterListBoxTag';

        ResultPanelTag = 'SearchRosBagResultPanelTag';
        ResultMainGridTag = 'SearchRosBagResultMainGridTag';
        ActiveFilterLabelTag = 'SearchRosBagActiveFilterLabelTag';
        TagLabelTag  = 'SearchRosBagTagLabelTag';
        TagPanelTag = 'SearchRosBagTagPanelTag';
        TagGridTag = 'SearchRosBagTagGridTag';
        BookmarkLabelTag = 'SearchRosBagBookmarkLabelTag';
        BookmarkPanelTag = 'SearchRosBagBookmarkPanelTag';
        BookmarkGridTag = 'SearchRosBagBookmarkGridTag';
        VisualizerLabelTag = 'SearchRosBagVisualizerLabelTag';
        VisualizerPanelTag = 'SearchRosBagVisualizerPanelTag';
        VisualizerGridTag = 'SearchRosBagVisualizerGridTag';
        SearchResultLabelTag = 'SearchRosBagSearchResultLabelTag';
        ResultsTableTag = 'SearchRosBagResultsTableTag';
        ClearTagTextAreaButtonTag = 'SearchRosBagClearTagTextAreaButtonTag';
        ClearBMTextAreaButtonTag = 'SearchRosBagClearBMTextAreaButtonTag';
        ClearVisualizerTextAreaButtonTag = 'SearchRosBagClearVisualizerTextAreaButtonTag';
        ExportToCSVResultsAreaButtonTag = 'SearchRosBagExportToCSVResultsAreaButtonTag';


        VisualizerItemsOnLoad = {' ', 'image', 'pointcloud', 'laserscan', 'odometry', 'numeric', 'message', 'map', 'marker', '3d'};
    end

    properties
        TagListBoxValueChangedFcn = function_handle.empty;
        BookmarkLisBoxtValueChangedFcn = function_handle.empty;
        VisualizerListValueChangedFcn = function_handle.empty;
        DeleteButtonClickedFcn = function_handle.empty;
    end

    methods
        function obj = UISearchRosbag()
            %ViewerBookmark Construct the search ui app
            obj.buildSearchUI
        end

        function showApp(obj)
            %showApp make the app visible
            obj.FigureHandle.Visible = matlab.lang.OnOffSwitchState.on;
        end

        function updateTagItems(obj, input)
            %updateTagItems update the tag item list
            obj.TagItemsOnLoad = input;
            obj.TagSFListBoxObj.Items = input;
        end

        function updateBmItems(obj, input)
            %updateBmItems update the bookmark item list
            obj.BMItemsOnLoad = input;
            obj.BookmarkSFListBoxObj.Items = input;
        end

        % All callback properties validate and set the same way
        function set.TagListBoxValueChangedFcn(obj, val)
            % setter to TagListBoxValueChangedFcn
            obj.TagListBoxValueChangedFcn = validateCallback(val, "TagListBoxValueChangedFcn");
        end

        function set.BookmarkLisBoxtValueChangedFcn(obj, val)
             % setter to BookmarkLisBoxtValueChangedFcn
            obj.BookmarkLisBoxtValueChangedFcn = validateCallback(val, "BookmarkLisBoxtValueChangedFcn");
        end

        function set.VisualizerListValueChangedFcn(obj, val)
            % setter to VisualizerListValueChangedFcn
            obj.VisualizerListValueChangedFcn = validateCallback(val, "VisualizerListValueChangedFcn");
        end

        function updateResultsTableData(obj, data)
            % update the search result table section
            appendExclamation = @(str) ['<a href="1">' str, '</a>'];
            dataCellArray = cellfun(appendExclamation, data, 'UniformOutput', false);
            obj.ResultsTableObj.Data = dataCellArray;
        end

        function closeApp(obj)
            % closeApp to close the app
            obj.FigureHandle.delete();
        end
    end

    methods (Access = protected)

        function buildSearchUI(obj)
            %buildSearchUI Create topic panel and initialize contents

            % Create figure and components
            obj.FigureHandle = uifigure("Position", .... [680 420 750 550], ...
                (ros.internal.utils.getWindowBounds).*[2.5 2 0.5 0.7], ...
                                        "Resize", matlab.lang.OnOffSwitchState.off, ...
                                        "Name", getString(message('ros:visualizationapp:view:SearchWindowTitle')), ...
                                        "Tag", obj.AppTag, ...
                                        "Visible", "off" , ...
                                        "WindowStyle", "modal");
            matlab.graphics.internal.themes.figureUseDesktopTheme(obj.FigureHandle);

            % main grid container for all the widgets
            obj.MainGridLayout = uigridlayout(obj.FigureHandle, 'Tag', obj.AppMainGridTag);
            obj.MainGridLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};
            obj.MainGridLayout.ColumnWidth = {'fit'};
            obj.MainGridLayout.Scrollable = matlab.lang.OnOffSwitchState.on;
            % Search filter title
            obj.SearchFilterTitleObj = uilabel(obj.MainGridLayout, ...
                                            "Text", getString(message("ros:visualizationapp:view:SearchFilterLabel")), ...
                                            "FontWeight", "bold", ...
                                            "Tag", obj.SearchFilterTitleTag);

            % tag search box
            obj.TagSFMainPanelObj = uipanel(obj.MainGridLayout, ...
                                            "BorderWidth", 0, ...
                                            "Title", upper(getString(message("ros:visualizationapp:view:TagsLabel"))), ...
                                            "FontWeight", "bold", ...
                                            "Tag", obj.TagSFMainPanelTag);
            obj.TagSFMainPanelObj.Scrollable = matlab.lang.OnOffSwitchState.on;

            obj.TagSFChildGridObj = uigridlayout(obj.TagSFMainPanelObj, "Tag", obj.TagSFChildGridTag);
            obj.TagSFChildGridObj.RowHeight = {24, '1x'};
            obj.TagSFChildGridObj.ColumnWidth = {'fit'};
            obj.TagSFChildGridObj.Scrollable = matlab.lang.OnOffSwitchState.on;

            obj.TagSFListBoxObj = uilistbox(obj.TagSFChildGridObj, ...
                                            "Multiselect", "off", ...
                                            "Tag", obj.TagSFListBoxTag);
            obj.TagSFListBoxObj.Layout.Row = 2;
            obj.TagSFListBoxObj.Layout.Column = 1;
            obj.TagSFEditFieldObj = uieditfield(obj.TagSFChildGridObj,  ...
                                                "ValueChangingFcn", ...
                                                @(source, event, x, y) obj.nValChanged(...
                                                source, event, obj.TagSFListBoxObj, obj.TagItemsOnLoad), ...
                                                "Tag", obj.TagSFEditFieldTag, ...
                                                "Placeholder", getString(message("ros:visualizationapp:view:SearchTagDefaultLabel")));
            obj.TagSFEditFieldObj.Layout.Row = 1;
            obj.TagSFEditFieldObj.Layout.Column = 1;


            % bookmark search box
            obj.BookmarkSFMainPanelObj = uipanel(obj.MainGridLayout, ...
                                                "BorderWidth", 0, ...
                                                "Title", upper(getString(message("ros:visualizationapp:view:BookmarkLabel"))), ...
                                                "FontWeight", "bold", "Tag", obj.BookmarkSFMainPanelTag);

            obj.BookmarkSFChildGridObj = uigridlayout(obj.BookmarkSFMainPanelObj, "Tag", obj.BookmarkSFChildGridTag);
            obj.BookmarkSFChildGridObj.RowHeight = {24, '1x'};
            obj.BookmarkSFChildGridObj.ColumnWidth = {'fit'};
            obj.BookmarkSFChildGridObj.Scrollable = matlab.lang.OnOffSwitchState.on;
            obj.BookmarkSFListBoxObj = uilistbox(obj.BookmarkSFChildGridObj, ...
                                                "Multiselect", "off", "Tag", obj.BookmarkSFListBoxTag);
            obj.BookmarkSFListBoxObj.Layout.Row = 2;
            obj.BookmarkSFListBoxObj.Layout.Column = 1;
            obj.BookmarkSFEditFieldObj = uieditfield(obj.BookmarkSFChildGridObj,  ...
                                                    "ValueChangingFcn", ...
                                                    @(source, event, x, y) obj.nValChanged(...
                                                    source, event, obj.BookmarkSFListBoxObj, obj.BMItemsOnLoad), ...
                                                    "Placeholder", getString(message("ros:visualizationapp:view:SearchBookmarkDefaultLabel")), ...
                                                    "Tag", obj.BookmarkSFEditFieldTag);
            obj.BookmarkSFEditFieldObj.Layout.Row = 1;
            obj.BookmarkSFEditFieldObj.Layout.Column =1;


            % Search Visualizer box
            obj.VisualizerSFMainPanelObj = uipanel(obj.MainGridLayout, ...
                                                    "BorderWidth", 0, ...
                                                    "FontWeight", "bold" , ...
                                                    "Title", upper(getString(...
                                                    message("ros:visualizationapp:view:VisualizersLabel"))), ...
                                                    "Tag", obj.VisualizerSFMainPanelTag);
            obj.VisualizerSFChildGridObj = uigridlayout(obj.VisualizerSFMainPanelObj, "Tag", obj.VisualizerSFChildGridTag);
            obj.VisualizerSFChildGridObj.RowHeight = {24, '1x'};
            obj.VisualizerSFChildGridObj.ColumnWidth = {'fit'};

            obj.VisualizerSFListBoxObj = uilistbox(obj.VisualizerSFChildGridObj, ...
                                                    "Multiselect", "off", ...
                                                    "Items", obj.VisualizerItemsOnLoad, ...
                                                    "Tag", obj.VisualizerSFListBoxTag);
            obj.VisualizerSFListBoxObj.Layout.Row = 2;
            obj.VisualizerSFListBoxObj.Layout.Column = 1;
            obj.VisualizerSFEditFieldObj = uieditfield(obj.VisualizerSFChildGridObj, ...
                                                    "ValueChangingFcn", ...
                                                    @(source, event, x, y) obj.nValChanged(...
                                                    source, event, obj.VisualizerSFListBoxObj, obj.VisualizerItemsOnLoad), ...
                                                    "Placeholder", getString(message("ros:visualizationapp:view:SearchVisualizerTypeDefaultLabel")), ...
                                                    "Tag", obj.VisualizerSFEditFieldTag);
            obj.VisualizerSFEditFieldObj.Layout.Row = 1;
            obj.VisualizerSFEditFieldObj.Layout.Column =1;


            %
            % Result Panel
            obj.ResultPanelObj =  uipanel(obj.MainGridLayout, "Tag", obj.ResultPanelTag);
            obj.ResultPanelObj.Layout.Column = 2;
            obj.ResultPanelObj.Layout.Row = [1  6];
            obj.ResultPanelObj.Scrollable = matlab.lang.OnOffSwitchState.on;

            % result main grid
            obj.ResultMainGridObj = uigridlayout(obj.ResultPanelObj, "Tag", obj.ResultMainGridTag);
            obj.ResultMainGridObj.RowHeight = {'fit', 25, 25, 25, 'fit', 'fit'};
            obj.ResultMainGridObj.ColumnWidth = {'fit', 400, 'fit'};
            obj.ResultMainGridObj.Scrollable = matlab.lang.OnOffSwitchState.on;

            % active filter label
            obj.ActiveFilterLabelObj = uilabel(obj.ResultMainGridObj, ...
                                            "FontWeight", "bold", ...
                                            "Tag", obj.ActiveFilterLabelTag, ...
                                            "Text",  getString(message("ros:visualizationapp:view:ActiveFilterLabel")));
            obj.ActiveFilterLabelObj.Layout.Row = 1;

            %
            obj.TagLabelObj = uilabel(obj.ResultMainGridObj, "Tag", obj.TagLabelTag);
            obj.TagLabelObj.Layout.Row = 2;
            obj.TagLabelObj.Layout.Column = 1;
            obj.TagLabelObj.Text = getString(message("ros:visualizationapp:view:TagsLabel"));

            obj.TagPanelObj = uitextarea(obj.ResultMainGridObj, "Tag", obj.TagPanelTag, "Editable", "off");
            obj.TagPanelObj.Layout.Row = 2;
            obj.TagPanelObj.Layout.Column = 2;

            obj.ClearTagTextAreaButtonObj = uibutton(obj.ResultMainGridObj, "Tag", obj.ClearTagTextAreaButtonTag);
            obj.ClearTagTextAreaButtonObj.Layout.Row = 2;
            obj.ClearTagTextAreaButtonObj.Layout.Column = 3;
            obj.ClearTagTextAreaButtonObj.Text = '';
            matlab.ui.control.internal.specifyIconID(obj.ClearTagTextAreaButtonObj, 'clearSearch', 12);


            %
            obj.BookmarkLabelObj = uilabel(obj.ResultMainGridObj, "Tag", obj.BookmarkLabelTag);
            obj.BookmarkLabelObj.Layout.Row = 3;
            obj.BookmarkLabelObj.Layout.Column = 1;
            obj.BookmarkLabelObj.Text = getString(message("ros:visualizationapp:view:BookmarkLabel"));

            obj.BookmarkPanelObj = uitextarea(obj.ResultMainGridObj, "Tag", obj.BookmarkPanelTag, "Editable", "off");
            obj.BookmarkPanelObj.Layout.Row = 3;
            obj.BookmarkPanelObj.Layout.Column = 2;

            obj.ClearBMTextAreaButtonObj = uibutton(obj.ResultMainGridObj, "Tag", obj.ClearBMTextAreaButtonTag);
            obj.ClearBMTextAreaButtonObj.Layout.Row = 3;
            obj.ClearBMTextAreaButtonObj.Layout.Column = 3;
            obj.ClearBMTextAreaButtonObj.Text = '';
            matlab.ui.control.internal.specifyIconID(obj.ClearBMTextAreaButtonObj, 'clearSearch', 12);

            %
            obj.VisualizerLabelObj = uilabel(obj.ResultMainGridObj,  "Tag", obj.VisualizerLabelTag);
            obj.VisualizerLabelObj.Layout.Row = 4;
            obj.VisualizerLabelObj.Layout.Column = 1;
            obj.VisualizerLabelObj.Text = getString(message("ros:visualizationapp:view:VisualizersLabel"));

            obj.VisualizerPanelObj = uitextarea(obj.ResultMainGridObj, "Tag",obj.VisualizerPanelTag, "Editable", "off");
            obj.VisualizerPanelObj.Layout.Row = 4;
            obj.VisualizerPanelObj.Layout.Column = 2;


            obj.ClearVisualizerTextAreaButtonObj = uibutton(obj.ResultMainGridObj, ...
                                        "Tag", obj.ClearVisualizerTextAreaButtonTag);
            obj.ClearVisualizerTextAreaButtonObj.Layout.Row = 4;
            obj.ClearVisualizerTextAreaButtonObj.Layout.Column = 3;
            obj.ClearVisualizerTextAreaButtonObj.Text = '';
            matlab.ui.control.internal.specifyIconID(obj.ClearVisualizerTextAreaButtonObj, 'clearSearch', 12);
            obj.ClearVisualizerTextAreaButtonObj.ButtonPushedFcn = @(source, event) obj.clearTextArea(source, event, obj.VisualizerPanelObj);

            %
            obj.SearchResultLabelObj = uilabel(obj.ResultMainGridObj, ...
                                            "Tag", obj.SearchResultLabelTag, ...
                                            "FontWeight", "bold");
            obj.SearchResultLabelObj.Layout.Row = 5;
            obj.SearchResultLabelObj.Layout.Column = 1;
            obj.SearchResultLabelObj.Text = getString(message("ros:visualizationapp:view:SearchResultLabel"));

            %
            obj.ResultsTableObj = uitable(obj.ResultMainGridObj, "Tag", obj.ResultsTableTag);
            obj.ResultsTableObj.Layout.Row = 6;
            obj.ResultsTableObj.Layout.Column = [1 3];
            obj.ResultsTableObj.RowName = '';
            obj.ResultsTableObj.ColumnName = '';
            obj.ResultsTableObj.Tooltip = 'click on the hyperlink to load the rosbag';
            tableStyle = uistyle("Interpreter", "html");
            addStyle(obj.ResultsTableObj,tableStyle);

            % Export search results button
            obj.ExportToCSVResultsAreaButtonObj = uibutton(obj.ResultMainGridObj, "Tag", obj.ExportToCSVResultsAreaButtonTag);
            obj.ExportToCSVResultsAreaButtonObj.Layout.Row = 5;
            obj.ExportToCSVResultsAreaButtonObj.Layout.Column = 3;
            obj.ExportToCSVResultsAreaButtonObj.Text = '';
            matlab.ui.control.internal.specifyIconID(obj.ExportToCSVResultsAreaButtonObj, 'export_find', 16);
        end

        function nValChanged(~, ~, event, listboxobj, items)
            %nValChanged - Create ValueChangedFcn callback
            newvalue = event.Value;
            listboxobj.Items = items; % whole dataset
            idx = contains(listboxobj.Items, newvalue,'IgnoreCase',true);
            if ~all(idx(:) == 0)% If empty
                Filtered_Values = listboxobj.Items(idx);
                listboxobj.Items = Filtered_Values;
            end
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
        "ViewerTags", ...
        propertyName)
end
end