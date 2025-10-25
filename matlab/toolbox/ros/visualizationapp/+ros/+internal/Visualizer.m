classdef (Abstract) Visualizer < handle
%This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

    properties % Access will be restricted to Presenter/tests, when created
               % Activate on new data source selection
               % This will require a function handle with the signature:
               % function callback(src, event, dataSourceID)
        DataSourceChangedCallback = function_handle.empty

        % Activate when closing the visualizer
        % This will require a function handle with the signature:
        % function callback(src, event)
        % Where "src" will be the visualizer handle
        CloseCallback = function_handle.empty
    end

    properties (SetAccess = protected)
        % Primary figure document for the visualizer
        Document

        IsDocumentClosing = false

        % Pairwise lists of data sources and graphics handles to update
        DataSources
        DataSourcesID
        GraphicsHandles

        % Handle to axes, to be used if visualizer uses axes
        AxesHandle

        % GridHandle
        GridHandle

        % AppMode : If bag file or live topic visualization is selected
        AppMode
    end

    properties (Abstract)
        % Initial title of the visualizer
        InitialTitle

        % Types of messages/fields that can be visualized
        % Options are defined by the topicTree object
        CompatibleTypes
    end

    properties (Constant)
        % Height (in pixels) of each data source selection
        DataSourceHeight = 22;

        % Data source initial label (placeholder)
        DataSourceLabel = getString(message('ros:visualizationapp:view:DataSourceLabel'));
        XDataSourceLabel = getString(message('ros:visualizationapp:view:XDataSourceLabel'));
        YDataSourceLabel = getString(message('ros:visualizationapp:view:YDataSourceLabel'));

        TagBaseGrid = 'RosbagViewerVisualizerGrid';
    end

    methods (Abstract)
        % Display new data based on specified topic/field path
        % This is expected to be called once per time step
        updateData(obj, dataSourcePath, data);
        
    end

    methods (Abstract, Access = protected)
        % Given the figure document, set up the internal layout
        buildInternals(obj);
    end

    methods (Static)
        function id = getNewID
        %getNewID Generate new unique identifier

            persistent lastID
            if isempty(lastID)
                lastID = 0;
            end
            id = lastID+1;
            lastID = id;
        end
    end
 
    methods
        function obj = Visualizer(appContainer, docGroupTag, appMode)
        %Visualizer Construct new visualizer object
        
        if nargin > 2
            obj.AppMode = appMode;
        else
            obj.AppMode = ros.internal.ViewerPresenter.RosbagVisualization;
        end

        % Create UI
            buildFrame(obj, appContainer, docGroupTag)
            crPgIdHdle = obj.launchCircularProgressIndicator();
            c = onCleanup(@()delete(crPgIdHdle));
            buildInternals(obj);

            % Ensure that closing the figure removes the visualizer
            obj.Document.CanCloseFcn = @(~) CloseRequestCallback(obj);
        end

        function reinit(obj)
            %reinit function is used to reinitialize the ui
            % components to its default values

            if numel(obj.DataSources) == 1
                obj.DataSources.Value = '';
            else
                for indx = 1:numel(obj.DataSources)
                    obj.DataSources(indx).Value = '';
                end
            end
            % reinitialize specific visualizer based UI Components. Each
            % visualizer can implement the following methods according to
            % the requirements. Empty implementation of the method is
            % created in this class. Visualizer can override the
            % implementation
            obj.reinitVisualizer();
        end

        function resetUI(obj)
            %resetUI function is used to reset the ui
           
            % reinitialize specific visualizer based UI Components. Each
            % visualizer can implement the following methods according to
            % the requirements. Empty implementation of the method is
            % created in this class. Visualizer can override the
            % implementation
            obj.reinitVisualizer();
        end

        function updateTimeSettings(obj, settings) %#ok<INUSD>
            %updateTimeSettings function is used to update visualizer with
            %latest time settings

            %This method is overridden in child classes where ever needed
        end

        function handle = launchCircularProgressIndicator(obj)
            % launchCircularProgressIndicator is used to launch the
            % circular progress indicator to show the loading status.

            
            % wait till the figure properties (Position) is in sync with
            % the actual value.
            % using while and drawnow approach to support webui 
            while ~(obj.Document.Figure.FigureViewReady)
                drawnow;
            end
            % remove line 151 to 153 and uncomment waitfor once g2505651 is
            % fixed
            %waitfor(obj.Document.Figure, 'FigureViewReady', true);
            % create circular progress Indicator 
            handle = ...
                matlab.ui.control.internal.CircularProgressIndicator(...
                'Parent', obj.Document.Figure, ...
                'Indeterminate', 'on'  );
     
            % Position to centre of the Visualizer
            % set the size to 30
            handle.Position = [obj.Document.Figure.Position(3)/2 obj.Document.Figure.Position(4)/2 30 30];
        end

        function delete(obj)
        % delete Remove the visualizer graphical components

        % Delete the visualizer figure if it is not already closing
            if ~obj.IsDocumentClosing
                delete(obj.Document)
            end

            % Perform externally-specified cleanup actions
            try
                makeCallback(obj, obj.CloseCallback, obj, [])
            catch ex
                warning(message("ros:visualizationapp:view:CloseCallbackError", ...
                                getReport(ex)))
            end
        end

        function set.DataSourceChangedCallback(obj, val)
            obj.DataSourceChangedCallback = validateCallback(obj, val, "DataSourceChangedCallback");
        end

        function updateDataSourceOptions(obj, topicTree)
        %updateDataSourceOptions Offer data sources based on new rosbag
            
            compatibleTopics = obj.getCompatibleTopics(topicTree);
            for k = 1:numel(obj.DataSources)
                obj.DataSources(k).Items = unique(vertcat({''}, compatibleTopics));
            end
        end

        function compatibleTopics = getCompatibleTopics(obj, topicTree)
            %getCompatibleTopics
            
            if ~isempty(topicTree)
                compatibleTopics = getDataSourcesWithTypes(topicTree, obj.CompatibleTypes);
            else
                compatibleTopics = {};
            end
        end

        function validateDataSources(obj)
            %validateDataSources function is used to validate the data
            %sources available in a visualizer.Visulizers can override 
            % this method if needed.

            for k = 1:numel(obj.DataSources)
                source = obj.DataSources(k);
                if ~ismember(source.Value, source.Items)
                    me = ros.internal.utils.getMException(...
                        'ros:visualizationapp:view:InvalidDataSources', ...
                        source.Value, obj.InitialTitle);
                    throw(me);
                end
            end
        end
    end

    methods (Access = protected)
        function buildFrame(obj, appContainer, docGroupTag)
        %buildFrame Create visualizer document

            figOptions.Title = obj.InitialTitle;
            figOptions.DocumentGroupTag = docGroupTag;
            obj.Document = matlab.ui.internal.FigureDocument(figOptions);
            % setting tag for UI testing purpose
            obj.Document.Tag = obj.InitialTitle + "Tag" + string(ros.internal.Visualizer.getNewID);
            obj.Document.EnableDockControls = 1; % enable dock/undock option 
            % check if there is an empty tile available
            if ~isempty(fieldnames(appContainer.DocumentLayout)) && ...
                        appContainer.DocumentLayout.tileCount >1 && ...
                        appContainer.DocumentLayout.emptyTileCount >0
                for indx = 1:numel(appContainer.DocumentLayout.tileOccupancy)
                    tileOcup = appContainer.DocumentLayout.tileOccupancy(indx);
                    if ~iscell(tileOcup) && isempty(tileOcup.children ) || isempty(tileOcup{1}.children ) 
                        emptyTileIndex = indx;
                        break;
                    end
                end
                obj.Document.Tile = emptyTileIndex;
            end
            add(appContainer, obj.Document);
            obj.GridHandle = uigridlayout(obj.Document.Figure, "Tag", obj.TagBaseGrid);
            obj.initializeGrid();
        end

        function initializeGrid(obj)
            obj.GridHandle.RowHeight = {obj.DataSourceHeight, '1x'};
            obj.GridHandle.ColumnWidth = {'1x'};
        end

        function allowClose = CloseRequestCallback(obj)
            %delete Perform clean up tasks and close the visualizer

            % Always allow the figure document to close
            allowClose = true;
            if isvalid(obj)
                % Set flag indicating that figure is already closing
                obj.IsDocumentClosing = true;

                % Destroy the visualizer object
                delete(obj)
            end
        end

        function tagValue = numberTag(obj, tagBase, index)
        %numberTag Get tag from tab base and data source ID
        %   index refers to which data source ID should be used. If not
        %   supplied, the first data source ID will be used.

            if nargin < 3
                index = 1;
            end
            tagValue = sprintf('%s_%d', tagBase, obj.DataSourcesID(index));
        end

        function makeCallback(~, fcn, varargin)
        %makeCallback Evaluate specified function with arguments if not empty

            if ~isempty(fcn)
                feval(fcn, varargin{:})
            end
        end

        function reinitVisualizer(obj) %#ok<MANU>
            %reinitVisualizer function is used to reinitialize the ui
            % components specific to the visualizer. Currently this method
            % is empty visulizer can override this method if needed.

        end
        
        function fHandle = validateCallback(~, fHandle, propertyName)
        %validateCallback Ensure callback has correct type

        % Accept any empty type to indicate no callback
            if isempty(fHandle)
                fHandle = function_handle.empty;
            else
                validateattributes(fHandle, ...
                                   "function_handle", ...
                                   "scalar", ...
                                   "Visualizer", ...
                                   propertyName)
            end
        end
    end
end
