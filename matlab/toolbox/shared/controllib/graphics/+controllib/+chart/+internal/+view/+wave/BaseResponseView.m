classdef BaseResponseView < matlab.mixin.SetGet & ...
                            matlab.mixin.Heterogeneous & ...
                            controllib.chart.internal.foundation.MixInListeners
    % controllib.chart.internal.view.wave.BaseResponseView(System)
    % -base class to create and manage response and characteristic graphics
    %  objects generated from a controllib.chart.internal.foundation.BaseResponse.
    %
    % h = BaseResponseView(Response)
    %
    % h = BaseResponseView(Response)
    %
    %
    % BaseResponse Properties (read-only)
    % 
    %   Response      Response that view is generated from
    %
    % BaseResponse Properties (protected)
    %
    %   ResponseLinesZData          ZData value for response lines
    %   CharacteristicMarkerZData   ZData value for characteristic markers
    %   CharacteristicLinesZData    ZData value for characteristic lines
    %
    % BaseResponse Methods (public)
    %
    %   setParent           Assign parent to response and characteristic graphics objects
    %   update              Update response and characteristics based on system
    %   updateStyle         Update response and characteristics style based on system style
    %   updateVisibility    Update response and characteristics visibility
    %
    % BaseResponse Methods (protected)
    %
    %   updateResponseStyle         Update response style
    %   updateCharacteristicStyle   Update characteristic style
    %   createLineObjects           Create line objects without data
    %
    % BaseResponse Methods (protected, overload if needed)
    %   createResponseLines             Create response line objects based on system data
    %   getResponseLines                Return response line objects
    %   updateResponseData              Update response line objects data
    %   updateResponseVisibility        Update visibility of response line objects
    %   createCharacteristicMarkers     Create characteristic markers and line objects
    %   getCharacteristicMarkers        Return characteristic marker objects
    %   getCharacteristicLines          Return characteristic line objects
    %   updateCharacteristicData        Update characteristic marker and line objects
    %   updateCharacteristicVisibility  Update visibility of characteristic marker and line objects
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        ColumnVisible (1,:) logical
        RowVisible (:,1) logical
        ArrayVisible logical

        Characteristics (:,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView

        LegendObjects (:,1) matlab.graphics.Graphics
        
        IsResponseViewValid (1,1) logical = false

        IsResponseDataTipsCreated (1,1) logical = false
    end

    properties (SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView},AbortSet=true)
        ColumnNames (1,:) string
        RowNames (:,1) string
    end

    properties (Dependent,SetAccess=private)
        CharacteristicTypes
    end

    properties (Hidden, SetAccess=immutable)
        Response
        PlotColumnIdx
        PlotRowIdx
    end

    properties (Access = private)
        GraphicsObjects (:,1) cell
        CustomDataTipLabels
    end
    
    %% Events
    events
        ResponseViewChanged
    end

    events (NotifyAccess = private, ListenAccess = private)
        ResponseGraphicsObjectStyleChanged
    end

    %% Constructor/destructor
    methods
        function this = BaseResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse
                optionalInputs.NRows (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                optionalInputs.NColumns (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                optionalInputs.ColumnVisible (1,:) logical = logical.empty
                optionalInputs.RowVisible (:,1) logical = logical.empty
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            % Store properties from Response
            this.Response = this.createResponseWrapper(response);
            this.Response.NRows = optionalInputs.NRows;
            this.Response.NColumns = optionalInputs.NColumns;

            if isempty(optionalInputs.ColumnVisible)
                optionalInputs.ColumnVisible = true(1,this.Response.NColumns);
            end
            if isempty(optionalInputs.RowVisible)
                optionalInputs.RowVisible = true(this.Response.NRows,1);
            end

            this.RowNames = repmat("",this.Response.NRows,1);
            this.ColumnNames = repmat("",1,this.Response.NColumns);
            this.RowVisible = optionalInputs.RowVisible;
            this.ColumnVisible = optionalInputs.ColumnVisible;
            this.ArrayVisible = optionalInputs.ArrayVisible;
            
            this.PlotColumnIdx = computePlotColumnIdx(this);
            this.PlotRowIdx = computePlotRowIdx(this);

            % Listener for nominal index changing
            L = addlistener(response,"NominalIndex","PostSet",...
                @(es,ed) cbResponseNominalIndexChanged(this));
            registerListeners(this,L,"ResponseNominalIndexListener");
            
            % Listener for name changing
            L = addlistener(response,"Name","PostSet",...
                @(es,ed) cbResponseNameChanged(this));
            registerListeners(this,L,"ResponseNameListener");

            % Add listener to modify style when response style is changed.
            L = addlistener(response,"StyleChanged",...
                @(es,ed) cbResponseStyleChanged(this));
            registerListeners(this,L,"ResponseStyleListener");

            % Add listener to update LegendDisplay of legend objects
            L = addlistener(response,"LegendDisplay","PostSet",...
                @(es,ed) set(this.LegendObjects,LegendDisplay=response.LegendDisplay & response.ShowInView));
            registerListeners(this,L,"LegendDisplayChangedListener");

            % Add listener to update LegendDisplay of legend objects when
            % setting ShowInView
            L = addlistener(response,"ShowInView","PostSet",...
                @(es,ed) set(this.LegendObjects,LegendDisplay=response.LegendDisplay & response.ShowInView));
            registerListeners(this,L,"ShowInViewChangedListener");

            % Add listener to update response style when line objects style
            % (LineWidth, Color, Marker, LineStyle) changes
            L = addlistener(this,'ResponseGraphicsObjectStyleChanged',@(es,ed) cbResponseGraphicsObjectsStyleChanged(this,ed,response));
            registerListeners(this,L,"ResponseStyleChanged");
        end

        function delete(this)
            unregisterListeners(this,"ResponseLinesDeleted");
            delete(this.Response);
            cellfun(@(x) delete(x),this.GraphicsObjects);
            delete(this.Characteristics);
            unregisterListeners(this);
        end
    end

    %% Public methods
    methods
        function deleteAllDataTips(this,rowIdx,columnIdx)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIdx (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
            end
            for ko = rowIdx
                if ~isempty(this.PlotRowIdx)
                    ko_idx = find(this.PlotRowIdx==ko,1);
                else
                    ko_idx = ko;
                end
                for ki = columnIdx
                    if ~isempty(this.PlotColumnIdx)
                        ki_idx = find(this.PlotColumnIdx==ki,1);
                    else
                        ki_idx = ki;
                    end
                    for ka = 1:this.Response.NResponses
                        
                        if ~isempty(ko_idx) && ko_idx <= this.Response.NRows && ...
                                ~isempty(ki_idx) && ki_idx <= this.Response.NColumns
                            % Delete for response lines
                            responseObjects = getResponseObjects(this,ko_idx,ki_idx,ka);
                            dataTipObjects = findobj(responseObjects{1},'Type','datatip');
                            delete(dataTipObjects);
                            % Delete for characteristic markers
                            charMarkers = getCharacteristicMarkers(this,ko_idx,ki_idx,ka);
                            dataTipObjects = findobj(charMarkers{1},'Type','datatip');
                            delete(dataTipObjects);
                        end
                    end
                end
            end
        end

        function updateVisibility(this,responseVisible,optionalInputs)
            % updateVisibility(this,System)
            %
            %   Update visibility of response line objects and
            %   characteristic objects based on System.Visible and
            %   System.ArrayVisible.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                responseVisible (1,1) logical = this.Response.Visible
                optionalInputs.ColumnVisible (1,:) logical...
                    {validateVisibilitySize(this,optionalInputs.ColumnVisible,'ColumnVisible')} = this.ColumnVisible
                optionalInputs.RowVisible (:,1) logical...
                    {validateVisibilitySize(this,optionalInputs.RowVisible,'RowVisible')} = this.RowVisible
                optionalInputs.ArrayVisible logical...
                    {validateVisibilitySize(this,optionalInputs.ArrayVisible,'ArrayVisible')} = this.ArrayVisible
            end            
            this.ArrayVisible = optionalInputs.ArrayVisible;
            this.ColumnVisible = optionalInputs.ColumnVisible;
            this.RowVisible = optionalInputs.RowVisible;

            arrayVisible = responseVisible & optionalInputs.ArrayVisible;
            columnVisible = responseVisible & optionalInputs.ColumnVisible;
            rowVisible = responseVisible & optionalInputs.RowVisible;
            
            updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible);
            for k = 1:length(this.Characteristics)
                charVisible = this.Characteristics(k).Visible;
                arrayVisible = charVisible & responseVisible & optionalInputs.ArrayVisible;
                columnVisible = charVisible & responseVisible & optionalInputs.ColumnVisible;
                rowVisible = charVisible & responseVisible & optionalInputs.RowVisible;
                updateCharacteristicVisibility(this,this.Characteristics(k).Type,...
                    RowVisible=rowVisible,ColumnVisible=columnVisible,ArrayVisible=arrayVisible);
            end

            if responseVisible && ~this.IsResponseDataTipsCreated
                createResponseDataTips(this);
            end
        end

        function r = getLegendObjects(this)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            r = this.LegendObjects;
        end
    end

    %% Get/Set
    methods
        % CharacteristicTypes
        function types = get.CharacteristicTypes(this)
            types = string.empty;
            if ~isempty(this.Characteristics)
                types = arrayfun(@(x) x.Type,this.Characteristics);
            end
        end

        % ColumnNames
        function set.ColumnNames(this,ColumnNames)
            this.ColumnNames = ColumnNames;
            updateColumnNames(this);
        end

        % RowNames
        function set.RowNames(this,RowNames)
            this.RowNames = RowNames;
            updateRowNames(this);
        end
    end

    %% Sealed methods
    methods (Sealed)
        function build(this)
            %   Create response objects. Update response data and
            %   characteristic data based on Response. Update visibility.
            
            % Create objects (implement in subclass if needed)
            createResponseObjects(this);
            createSupportingObjects(this);

            % Create legend objects (from subclass) and add tags
            legendObjects = createLegendObjects(this);
            for k = 1:length(legendObjects)
                legendObjects(k).Tag = "legendObjectForControlChartResponse_" + ...
                    this.Response.Tag;
                legendObjects(k).LegendDisplay = this.Response.LegendDisplay;
            end
            this.LegendObjects = legendObjects(:);

            % Create characteristics
            createCharacteristics(this,this.Response.ResponseData);

            % Update objects with latest information
            update(this);
            updateStyle(this,this.Response.Style);
            updateVisibility(this,this.Response.Visible);
            % createResponseDataTips(this);

            this.IsResponseViewValid = true;

            
            
            % Add listener to response lines being deleted
            allResponseObjects = matlab.graphics.GraphicsPlaceholder.empty;
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        responseLine = getResponseObjects(this,ko,ki,ka);
                        allResponseObjects = [allResponseObjects(:); responseLine{1}(:)];
                    end
                end
            end

            L = addlistener(allResponseObjects,'Selected','PostSet',...
                @(es,ed) cbResponseLineSelectionChanged(es,ed,allResponseObjects));
            registerListeners(this,L,...
                repmat("ResponseGraphicsObjectSelectionChangedListener",size(L)));
            function cbResponseLineSelectionChanged(es,ed,allResponseObjects)
                value = ed.AffectedObject.Selected;
                hfigure = get(groot, 'CurrentFigure');
                unregisterListeners(this,"StyleChangedInToolstripListener")

                if strcmpi(value, 'on')
                    
                    disableListeners(this,"ResponseGraphicsObjectSelectionChangedListener");
                    selectObjs = getselectobjects(hfigure);
                    unSlectedObjs = setdiff(allResponseObjects, selectObjs);
                    selectobject(unSlectedObjs,'on');

                    % Add listeners on a line object to propagate style
                    % changes to the Response object
                    if ~isempty(selectObjs)
                        isLineObject = strcmp(get(allResponseObjects,'Type'),'line');
                        isStairObject = strcmp(get(allResponseObjects,'Type'),'stair');
                        isStemObject = strcmp(get(allResponseObjects,'Type'),'stem');
                        idxForLineObject = find(isLineObject | isStairObject | isStemObject,1,'first');
                        hSelectedLine = allResponseObjects(idxForLineObject);
                        styleChangedListener = addlistener(hSelectedLine,{'LineStyle','LineWidth',...
                            'Marker','MarkerSize','Color'},'PostSet',@(es,ed) cbStyleChangedInPlotEditMode(this,es,ed));
                        registerListeners(this,styleChangedListener,"StyleChangedInToolstripListener");
                    end
                    enableListeners(this,"ResponseGraphicsObjectSelectionChangedListener");
                end
                
            end
            
            function cbStyleChangedInPlotEditMode(this,es,ed)
                eventData = controllib.chart.internal.utils.GenericEventData;
                eventData.Data.PropertyChanged = ed.Source.Name;
                eventData.Data.Value = ed.AffectedObject.(ed.Source.Name);
                notify(this,"ResponseGraphicsObjectStyleChanged",eventData);
            end

            function cbResponseLineDeleted(this)
                delete(getResponse(this.Response));
            end
        end

        function characteristicObjects = getCharacteristic(this,type)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                type (:,1) string
            end
            characteristicObjects = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            idx = [];
            for k = 1:length(type)
                if ~isempty(this.Characteristics)
                    idx = [idx, find(this.CharacteristicTypes == type(k))]; %#ok<AGROW>
                end
            end
            if ~isempty(idx)
                characteristicObjects = this.Characteristics(idx);
            end
        end    

        function r = getResponseObjects(this,rowIndex,columnIndex,arrayIndex) 
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        r{ko,ki,ka} = getResponseObjects_(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                    end
                end
            end
        end

        function r = getSupportingObjects(this,rowIndex,columnIndex,arrayIndex)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        r{ko,ki,ka} = getSupportingObjects_(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                    end
                end
            end
        end

        function r = getCharacteristicMarkers(this,rowIndex,columnIndex,arrayIndex)
            % c = getCharacteristicMarkers(this,outputIndex,inputIndex,arrayIndex)
            %
            %   Return all characteristic marker objects based on indexing.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        for k = 1:length(this.Characteristics)
                            objects = getMarkerObjects(this.Characteristics(k),rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                            if ~isempty(objects{1})
                                if isempty(r{ko,ki,ka})
                                    r{ko,ki,ka} = objects{1};
                                else
                                r{ko,ki,ka} = cat(3,r{ko,ki,ka},objects{1});
                                end
                            end
                        end
                    end
                end
            end
        end

        function r = getCharacteristicResponseObjects(this,rowIndex,columnIndex,arrayIndex)
            % p = getCharacteristicPatches(this,outputIndex,inputIndex,arrayIndex)
            %
            %   Return all characteristic objects based on indexing
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        for k = 1:length(this.Characteristics)
                            objects = getResponseObjects(this.Characteristics(k),rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                            if ~isempty(objects{1})
                                r{ko,ki,ka} = cat(3,r{ko,ki,ka},objects{1});
                            end
                        end
                    end
                end
            end
        end

        function r = getCharacteristicSupportingObjects(this,rowIndex,columnIndex,arrayIndex)
            % p = getCharacteristicPatches(this,outputIndex,inputIndex,arrayIndex)
            %
            %   Return all characteristic objects based on indexing
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        for k = 1:length(this.Characteristics)
                            objects = getSupportingObjects(this.Characteristics(k),rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                            if ~isempty(objects{1})
                                r{ko,ki,ka} = cat(3,r{ko,ki,ka},objects{1});
                            end
                        end
                    end
                end
            end
        end

        function setParent(this,ax,gridSize,subGridSize)
            %   Set the parent of response and characteristic
            %   graphics objects to axes array ax.
            arguments
                this (:,1) controllib.chart.internal.view.wave.BaseResponseView
                ax (:,:) matlab.graphics.axis.Axes
                gridSize (1,2) double {mustBeInteger,mustBePositive}
                subGridSize (1,2) double {mustBeInteger,mustBePositive,validateAxesSubGridSize(this,ax,subGridSize)} = [1 1]
            end

            % The order of the parenting is important, since it is used to
            % control the "depth" of the graphics object without specifying
            % the ZData. The order from bottom layer to top is ..
            %
            %  - Supporting objects (e.g. steady state line in time plots)
            %  - Characteristic supporting objects (e.g. thresholds for settling time)
            %  - Characteristic response objects (e.g. confidence regions)
            %  - Response objects (e.g. step)
            %  - Characteristic markers (e.g peak response)

            axGroups = cell(subGridSize);
            for ii = 1:subGridSize(1)
                for jj = 1:subGridSize(2)
                    axGroups{ii,jj} = ax(ii:subGridSize(1):size(ax,1),jj:subGridSize(2):size(ax,2));
                end
            end

            % Get handles to graphics objects
            allObjects = cell(5,length(this));
            for k = 1:length(this)
                allObjects{1,k} = getCharacteristicMarkers(this(k));
                allObjects{2,k} = getResponseObjects(this(k));
                allObjects{3,k} = getCharacteristicResponseObjects(this(k));
                allObjects{4,k} = getCharacteristicSupportingObjects(this(k));
                allObjects{5,k} = getSupportingObjects(this(k));
            end

            % Sort on per-axes basis
            rowsGrouped = size(ax,1) > subGridSize(1) && ax(1,1) == ax(1+subGridSize(1),1);
            columnsGrouped = size(ax,2) > subGridSize(2) && ax(1,1) == ax(1,1+subGridSize(2));
            if rowsGrouped
                nRows = subGridSize(1);
            else
                nRows = size(ax,1);
            end
            if columnsGrouped
                nColumns = subGridSize(2);
            else
                nColumns = size(ax,2);
            end
            allObjectsPerAx = cell(nRows,nColumns);
            
            % Get maximum rows and columns for axes
            maxNRows = gridSize(1);
            maxNColumns = gridSize(2);
            for nn = 1:5 %each layer
                for k = length(this):-1:1 %each response, load in reverse order, most recent response on top
                    for ko = maxNRows:-1:1 %each grid row
                        ko_idx = find(this(k).PlotRowIdx==ko, 1);
                        for ki = maxNColumns:-1:1 %each grid column
                            ki_idx = find(this(k).PlotColumnIdx==ki, 1);
                            for ka = this(k).Response.NResponses:-1:1 %each array
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    objects = allObjects{nn,k}{ko_idx,ki_idx,ka};
                                    if ~isempty(objects)
                                        for ii = subGridSize(1):-1:1 %each subgrid row
                                            for jj = subGridSize(2):-1:1 %each subgrid column
                                                if rowsGrouped
                                                    kr = ii;
                                                else
                                                    kr = (ko-1)*subGridSize(1)+ii;
                                                end
                                                if columnsGrouped
                                                    kc = jj;
                                                else
                                                    kc = (ki-1)*subGridSize(2)+jj;
                                                end
                                                allObjectsPerAx{kr,kc} = cat(3,allObjectsPerAx{kr,kc},objects(ii,jj,:));
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            % Parent objects
            for kr = 1:nRows
                for kc = 1:nColumns
                    objects = allObjectsPerAx{kr,kc};
                    set(objects,Parent=ax(kr,kc),ContextMenu=ax(kr,kc).ContextMenu);
                end
            end

            % Reorder objects
            for kr = 1:nRows
                for kc = 1:nColumns
                    objects = squeeze(allObjectsPerAx{kr,kc});
                    customChildren = setdiff(ax(kr,kc).Children,objects);
                    isGridLine = arrayfun(@(x) strcmp(x.Tag,'CSTgridLines'),customChildren);
                    gridLines = customChildren(isGridLine);
                    customChildren = customChildren(~isGridLine);
                    ax(kr,kc).Children = [customChildren(:);objects;gridLines(:)];
                end
            end

            % Set Parent on legend lines
            % legendLine = getLegendObjects(this);
            % if ~isempty(ax)
            %     legendLine.Parent = ax(1);
            % else
            %     legendLine.Parent = [];
            % end
        end

        function unParent(this)
            for k = 1:length(this)
                m = localConvertToVector(getCharacteristicMarkers(this(k)));
                r = localConvertToVector(getResponseObjects(this(k)));
                cr = localConvertToVector(getCharacteristicResponseObjects(this(k)));
                cs = localConvertToVector(getCharacteristicSupportingObjects(this(k)));
                s = localConvertToVector(getSupportingObjects(this(k)));
            end
            allObjectsInAnArray = [m;r;cr;cs;s];
            set(allObjectsInAnArray,Parent=[]);

            function m = localConvertToVector(m)
                m = [m{:}];
                m = m(:);
            end
        end

        function setCharacteristicVisible(this,characteristicType,characteristicVisible)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                characteristicType (:,1) string
                characteristicVisible (1,1) matlab.lang.OnOffSwitchState
            end

            characteristicObjects = getCharacteristic(this,characteristicType);
            
            % Set visibility
            for k = 1:length(characteristicObjects)
                if characteristicObjects(k).Visible ~= characteristicVisible
                    setVisible(characteristicObjects(k),characteristicVisible & this.Response.Visible,...
                        InputVisible = this.ColumnVisible,...
                        OutputVisible = this.RowVisible,...
                        ArrayVisible = this.ArrayVisible);
                end
            end
        end
        
        function update(this)
            %   Update the response and characteristic object data and
            %   style based on Response. Notifies the "ResponseViewChanged"
            %   event.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            updateResponseData(this);
            if ~isempty(this.Characteristics)
                updateCharacteristic(this,this.CharacteristicTypes);
            end
            cbResponseDataTipInfoChanged(this);
            notify(this,'ResponseViewChanged');
        end
        
        function updateStyle(this,Style)
            % updateStyle(this,Style)
            %
            %   Update the style of the response line objects (Color,
            %   LineStyle, LineWidth, MarkerStyle, MarkerSize) and
            %   characteristic marker objects (Color, MarkerStyle,
            %   MarkerSize).
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                Style (1,1) controllib.chart.internal.options.ResponseStyle
            end
            updateResponseStyle(this,Style);
            updateCharacteristicStyle(this,Style);
        end

        function updateCharacteristic(this,characteristicType)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                characteristicType (:,1) string {validateCharacteristicType(this,characteristicType)} ...
                    = this.CharacteristicTypes
            end
            characteristicObjects = getCharacteristic(this,characteristicType);
            for k = 1:length(characteristicObjects)
                update(characteristicObjects(k));
            end
        end

        function updateCharacteristicByLimits(this,characteristicType)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                characteristicType (:,1) string {validateCharacteristicType(this,characteristicType)} ...
                    = this.CharacteristicTypes
            end
            characteristicObjects = getCharacteristic(this,characteristicType);
            for k = 1:length(characteristicObjects)
                updateByLimits(characteristicObjects(k));
            end
        end

        function buildCharacteristic(this,characteristicType)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                characteristicType (:,1) string {validateCharacteristicType(this,characteristicType)} ...
                    = this.CharacteristicTypes
            end
            characteristicObjects = getCharacteristic(this,characteristicType);
            for k = 1:length(characteristicObjects)
                build(characteristicObjects(k));
                % if this.IsResponseDataTipsCreated && characteristicObjects(k).IsInitialized
                %     createDataTips(characteristicObjects(k));
                % end
            end
        end
    end

    %% Protected methods (to override in subclass)
    methods(Access = protected)
        function updateCharacteristicVisibility(this,characteristicType,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                characteristicType (:,1) string {validateCharacteristicType(this,characteristicType)} ...
                    = this.CharacteristicTypes
                optionalInputs.ColumnVisible (1,:) logical...
                    {validateVisibilitySize(this,optionalInputs.ColumnVisible,'ColumnVisible')} = this.ColumnVisible
                optionalInputs.RowVisible (:,1) logical...
                    {validateVisibilitySize(this,optionalInputs.RowVisible,'RowVisible')} = this.RowVisible
                optionalInputs.ArrayVisible logical...
                    {validateVisibilitySize(this,optionalInputs.ArrayVisible,'ArrayVisible')} = this.ArrayVisible
            end
            characteristicObjects = getCharacteristic(this,characteristicType);
            for k = 1:length(characteristicObjects)
                if characteristicObjects(k).IsInitialized
                    setVisible(characteristicObjects(k),InputVisible=optionalInputs.ColumnVisible,...
                        OutputVisible=optionalInputs.RowVisible,...
                        ArrayVisible=optionalInputs.ArrayVisible);
                end
            end
        end

        function createResponseObjects(this)
            % createResponseObjects(this)
            %
            %   Create response graphics objects. Implement in sub class.
        end

        function createSupportingObjects(this)
            % createSupportingObjects(this,System)
            %
            %   Create supporting graphics objects. Implement in sub class.
        end

        function legendObjects = createLegendObjects(this)
            % legendObjects = createLegendObjects(this,System)
            %
            %   Create and return legend graphics objects. Implement in sub class.
            %   Set DisplayName property to enable legend.
            legendObjects = matlab.graphics.GraphicsPlaceholder.empty;
        end

        function r = getResponseObjects_(this,outputIndex,inputIndex,arrayIndex)
            % r = getResponseLines(this,outputIndex,inputIndex,arrayIndex)
            %
            % Return response line object based on indexing. Implement in
            % sub class.
            r = matlab.graphics.primitive.Data.empty;
        end

        function r = getSupportingObjects_(this,outputIndex,inputIndex,arrayIndex)
            % r = getSupportingLines(this,outputIndex,inputIndex,arrayIndex)
            %
            % Return line object for supporting lines (like steady-state)
            % based on indexing. Implement in sub class.
            r = matlab.graphics.primitive.Data.empty;
        end        

        function updateResponseStyle_(this,styleValue,ko,ki,ka)
            % updateResponseStyle_(this,styleValue,outputIndex,inputIndex,arrayIndex)
            %
            %   Implement in sub class if needed
        end

        function updateResponseData(this)
            % updateResponseData(this,System)
            %
            %   Update the XData and YData of response objects.
            %   Implement in sub class.
        end

        function updateResponseVisibility(this,rowVisible,columnVisible,arrayVisible)
            % updateResponseVisibility(this,System)
            %
            %   Update the visibility of the response line objects based on
            %   System.Visible and System.ArrayVisible. Implement in sub
            %   class.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowVisible (:,1) logical
                columnVisible (1,:) logical
                arrayVisible logical
            end
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        visibilityFlag = arrayVisible(ka) & rowVisible(ko) & columnVisible(ki);
                        responseObjects = getResponseObjects(this,ko,ki,ka);
                        set(responseObjects{1},Visible=visibilityFlag);
                    end
                end
            end

            visibilityFlag = any(arrayVisible,'all') & any(rowVisible,'all') & any(columnVisible,'all');
            legendObjects = getLegendObjects(this);
            set(legendObjects,Visible=visibilityFlag);
        end

        function updateResponseStyle(this,Style)
            % updateResponseStyle(this,Style)
            %
            %   Update style (Color, LineStyle, LineWidth, MarkerStyle,
            %   MarkerSize) of all response line objects.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                Style (1,1) controllib.chart.internal.options.ResponseStyle
            end
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        rObjects = getResponseObjects(this,ko,ki,ka);
                        if ka == 1
                            lgdObjects = getLegendObjects(this);
                            if ~isempty(lgdObjects)
                                rObjects = {[rObjects{1}(:);lgdObjects(:)]};
                            end
                        end
                        styleValue = getValue(Style,OutputIndex=ko,InputIndex=ki,ArrayIndex=ka);
                        sv = fieldnames(styleValue);
                        for ii = 1:length(sv)
                            if ~isprop(this.Response,sv{ii})
                                styleValue = rmfield(styleValue,sv{ii});
                            end
                        end
                        for k = 1:numel(rObjects{1})
                            if isfield(styleValue,'Color') || isfield(styleValue,'FaceColor')
                                if isprop(rObjects{1}(k),'Color')
                                    if isfield(styleValue,'Color')
                                        styleColor = styleValue.Color;
                                    else
                                        styleColor = styleValue.FaceColor;
                                    end
                                    if ~isempty(this.Response.NominalIndex) && this.Response.NominalIndex ~= ka
                                        if isnumeric(styleColor)
                                            styleColor = [styleColor, 0.3]; %#ok<AGROW>
                                        else
                                            % SemanticColor specified
                                            styleColor = controllib.plot.internal.utils.convertSemanticColor(...
                                                styleColor,"tertiary");
                                        end
                                    end
                                    controllib.plot.internal.utils.setColorProperty(...
                                        rObjects{1}(k),"Color",styleColor);
                                elseif isprop(rObjects{1}(k),'FaceColor')
                                    if isfield(styleValue,'FaceColor')
                                        controllib.plot.internal.utils.setColorProperty(...
                                            rObjects{1}(k),"FaceColor",styleValue.FaceColor);
                                        controllib.plot.internal.utils.setColorProperty(...
                                            rObjects{1}(k),"EdgeColor",styleValue.EdgeColor);
                                        rObjects{1}(k).FaceAlpha = styleValue.FaceAlpha;
                                        rObjects{1}(k).EdgeAlpha = styleValue.EdgeAlpha;
                                    else
                                        controllib.plot.internal.utils.setColorProperty(...
                                            rObjects{1}(k),["FaceColor","EdgeColor"],styleValue.Color);
                                        rObjects{1}(k).FaceAlpha = 1;
                                        rObjects{1}(k).EdgeAlpha = 1;
                                    end
                                elseif isprop(rObjects{1}(k),'MarkerEdgeColor')
                                    if isfield(styleValue,'Color')
                                        controllib.plot.internal.utils.setColorProperty(...
                                            rObjects{1}(k),"MarkerEdgeColor",styleValue.Color);
                                    else
                                        controllib.plot.internal.utils.setColorProperty(...
                                            rObjects{1}(k),"MarkerEdgeColor",styleValue.EdgeColor);
                                    end
                                end
                            end
                            if isprop(rObjects{1}(k),'LineStyle') && isfield(styleValue,'LineStyle')
                                rObjects{1}(k).LineStyle = styleValue.LineStyle;
                            end
                            if isprop(rObjects{1}(k),'LineWidth') && isfield(styleValue,'LineWidth')
                                rObjects{1}(k).LineWidth = styleValue.LineWidth;
                            end
                            if ~strcmp(rObjects{1}(k).Type,'patch') && isprop(rObjects{1}(k),'Marker') && isfield(styleValue,'MarkerStyle')
                                rObjects{1}(k).Marker = styleValue.MarkerStyle;
                            end
                            if isfield(styleValue,'MarkerSize')
                                if isprop(rObjects{1}(k),'MarkerSize')
                                    rObjects{1}(k).MarkerSize = styleValue.MarkerSize;
                                elseif isprop(rObjects{1}(k),'SizeData')
                                    rObjects{1}(k).SizeData = styleValue.MarkerSize^2;
                                end
                            end
                        end
                        updateResponseStyle_(this,styleValue,ko,ki,ka);
                    end
                end
            end
        end
        
        function createCharacteristics(this,data)  

        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,~,customDataTipRows) %#ok<*INUSD>

        end

        function cbResponseNominalIndexChanged(this)
            updateResponseStyle(this,this.Response.Style);
            updateVisibility(this);
        end

        function cbResponseNameChanged(this)
            lgdObjects = getLegendObjects(this);
            for kr = 1:numel(lgdObjects)
                lgdObjects(kr).DisplayName = strrep(this.Response.Name,'_','\_');
            end
            
            if this.IsResponseDataTipsCreated
                responseObjects = getResponseObjects(this);
                for ka = 1:length(responseObjects)
                    nameLabel = getNameLabel(this,ka);
                    for kr = 1:length(responseObjects{ka})
                        if isprop(responseObjects{ka}(kr),'DataTipTemplate')
                            controllib.chart.internal.view.wave.BaseResponseView.replaceDataTipRowValue(...
                                responseObjects{ka}(kr),getString(message('Controllib:plots:strResponse')),...
                                @(x) nameLabel);
                        end
                    end
                end
            end
        end

        function cbResponseStyleChanged(this)
            updateStyle(this,this.Response.Style);
        end

        function cbResponseDataTipInfoChanged(this)
            % Store old labels before generating new dataTipRows
            oldCustomDataTipLabels = this.CustomDataTipLabels;
            this.CustomDataTipLabels = [];
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        % Create new dataTipRows
                        customDataTipRows = getCustomDataTipRows(this,ko,ki,ka);
                        % Get response graphics objects
                        responseObjects = getResponseObjects(this,ko,ki,ka);
                        responseObjects = responseObjects{1};
                        if isempty(oldCustomDataTipLabels)
                            oldCustomDataTipLabels_k = [];
                        else
                            oldCustomDataTipLabels_k = oldCustomDataTipLabels{ka}{ko,ki};
                        end
                        % Loop over all response objects
                        for kr = 1:length(responseObjects)
                            if isprop(responseObjects(kr),'DataTipTemplate')
                                % Compute the index of the old dataTipRow
                                % that needs to be removed
                                idxToRemove = [];
                                for k = 1:length(oldCustomDataTipLabels_k)
                                    labelToFind = oldCustomDataTipLabels_k{k};
                                    idx = controllib.chart.internal.view.wave.BaseResponseView.findDataTipRowIndexByLabel(...
                                        responseObjects(kr),labelToFind);
                                    idxToRemove = [idxToRemove, idx]; %#ok<AGROW>
                                end
                                % Replace old dataTipRows with new ones
                                % (remove extra ones)
                                for k = 1:length(idxToRemove)
                                    if k <= numel(customDataTipRows)
                                        responseObjects(kr).DataTipTemplate.DataTipRows(idxToRemove(k)) = ...
                                            customDataTipRows(k);
                                    else
                                        responseObjects(kr).DataTipTemplate.DataTipRows(idxToRemove(k)) = [];
                                        idxToRemove(k+1:end) = idxToRemove(k+1:end)-1;
                                    end
                                end
                                % Add the extra new data tip rows
                                if numel(customDataTipRows) > length(oldCustomDataTipLabels_k)
                                    customDataTipRowsToAdd = customDataTipRows(length(idxToRemove)+1:end);
                                    if isempty(idxToRemove)
                                        responseObjects(kr).DataTipTemplate.DataTipRows = ...
                                            [responseObjects(kr).DataTipTemplate.DataTipRows; customDataTipRowsToAdd(:)];
                                    else
                                        responseObjects(kr).DataTipTemplate.DataTipRows = ...
                                            [responseObjects(kr).DataTipTemplate.DataTipRows(1:idxToRemove(k));...
                                            customDataTipRowsToAdd(:);...
                                            responseObjects(kr).DataTipTemplate.DataTipRows(idxToRemove(k)+1:end)];
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        function nameRow = getNameDataTipRow(this,ka)
            nameLabel = getNameLabel(this,ka);
            nameRow = dataTipTextRow(getString(message('Controllib:plots:strResponse')),@(x) nameLabel);
        end

        function ioRow = getIODataTipRow(this,columnIdx,rowIdx)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                columnIdx (1,1) double {mustBePositive, mustBeInteger} = 1
                rowIdx (1,1) double {mustBePositive, mustBeInteger} = 1
            end
            if (this.Response.NColumns > 1 || this.Response.NRows > 1 || ...
                    (~isempty(this.PlotColumnIdx) && max(this.PlotColumnIdx) > 1) || ...
                    (~isempty(this.PlotRowIdx) && max(this.PlotRowIdx) > 1)) && ...
                    length(this.ColumnNames) >= columnIdx && length(this.RowNames) >= rowIdx
                ioLabel = getString(message('Controllib:plots:InputToOutput',this.ColumnNames(columnIdx),...
                    this.RowNames(rowIdx)));
                ioRow = dataTipTextRow(getString(message('Controllib:plots:strIO')),@(x) string(ioLabel));
            else
                ioRow = matlab.graphics.datatip.DataTipTextRow.empty;
            end
        end

         function updateColumnNames(this)
            for k = 1:length(this.Characteristics)
                updateIODataTipRow(this.Characteristics(k));
            end
            if this.IsResponseViewValid
                updateIODataTipRow(this);
            end
        end

        function updateIODataTipRow(this)
            if this.IsResponseDataTipsCreated
                % Update response data tips
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        ioRow = getIODataTipRow(this,ki,ko);
                        if isempty(ioRow)
                            continue;
                        end
                        for ka = 1:this.Response.NResponses
                            responseObjects = getResponseObjects(this,ko,ki,ka);
                            for k = 1:numel(responseObjects{1})
                                if isprop(responseObjects{1}(k),'DataTipTemplate')
                                    idx = find(contains({responseObjects{1}(k).DataTipTemplate.DataTipRows.Label},...
                                        getString(message('Controllib:plots:strIO'))),1);
                                    if ~isempty(idx)
                                        responseObjects{1}(k).DataTipTemplate.DataTipRows(idx) = ioRow;
                                    end
                                end
                            end
                        end
                    end
                end

                % Update characteristic data tips
                for k = 1:length(this.Characteristics)
                    updateIODataTipRow(this.Characteristics(k));
                end
            end
        end
        
        function updateRowNames(this)
            for k = 1:length(this.Characteristics)
                updateIODataTipRow(this.Characteristics(k));
            end
            if this.IsResponseViewValid
                updateIODataTipRow(this);
            end
        end

        function customDataTipRows = getCustomDataTipRows(this,ko,ki,ka)
            if isempty(this.Response.DataTipInfo)
                customDataTipRows = matlab.graphics.datatip.DataTipTextRow.empty;
                this.CustomDataTipLabels{ka}{ko,ki} = {char.empty};
            else
                customDataTipInfo = this.Response.DataTipInfo{ka}(ko,ki);
                customDataTipLabels = fieldnames(customDataTipInfo);
                customDataTipRows = createArray([length(customDataTipLabels) 1],'matlab.graphics.datatip.DataTipTextRow');
                for k = 1:length(customDataTipLabels)
                    customDataTipRows(k) = dataTipTextRow(customDataTipLabels{k},...
                        @(x) customDataTipInfo.(customDataTipLabels{k}));
                end
                this.CustomDataTipLabels{ka}{ko,ki} = {customDataTipRows.Label};
            end
        end
    
        function setLegendDisplay(this,legendDisplay)     
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                legendDisplay (1,1) matlab.lang.OnOffSwitchState
            end
            lgdObjects = getLegendObjects(this);
            for kr = 1:numel(lgdObjects)
                lgdObjects(kr).LegendDisplay = legendDisplay;
            end
        end
    end

    %% Protected sealed methods
    methods (Sealed,Access = protected) 
        function hObjects = createGraphicsObjects(this,type,nRows,nColumns,nArray,optionalInputs)
            % Create an array of graphics objects
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                type (1,1) string {mustBeMember(type,...
                    ["scatter";"line";"stair";"stem";"patch";"bar";...
                    "constantLine";"constantRegion";"rectangle";"text"])}
                nRows (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                nColumns (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                nArray (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                optionalInputs.Tag (1,:) char = ''
                optionalInputs.HitTest (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.PickableParts (1,:) char...
                    {mustBeMember(optionalInputs.PickableParts,{'visible','all','none'})} = 'visible'
                optionalInputs.HandleVisibility (1,:) char = 'on'
                optionalInputs.DisplayName (1,:) char = ''
            end
            if ~isempty(optionalInputs.DisplayName)
                optionalInputs.LegendDisplay = 'on';
            end
            optionalInputs = namedargs2cell(optionalInputs);
            switch type
                case "scatter"
                    hObjects = this.createScatterObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "line"
                    hObjects = this.createLineObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "stair"
                    hObjects = this.createStairObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "stem"
                    hObjects = this.createStemObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "patch"
                    hObjects = this.createPatchObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "bar"
                    hObjects = this.createBarObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "constantLine"
                    hObjects = this.createConstantLineObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "constantRegion"
                    hObjects = this.createConstantRegionObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "rectangle"
                    hObjects = this.createRectangleObjects(nRows,nColumns,nArray,optionalInputs{:});
                case "text"
                    hObjects = this.createTextObjects(nRows,nColumns,nArray,optionalInputs{:});
            end
            this.GraphicsObjects{end+1} = hObjects;
        end  

        function updateCharacteristicStyle(this,Style)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                Style (1,1) controllib.chart.internal.options.ResponseStyle
            end
            characteristicObjects = getCharacteristic(this,this.CharacteristicTypes);
            for k = 1:length(characteristicObjects)
                if characteristicObjects(k).IsInitialized
                    updateStyle(characteristicObjects(k),Style);
                end
            end
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function responseWrapper = createResponseWrapper(response)
            arguments
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseWrapper = controllib.chart.internal.view.wave.data.ResponseWrapper(response);
        end
    end

    %% Static protected sealed methods
    methods (Static,Sealed,Access = protected)
        function disableDataTipInteraction(graphicsObjects)
            arguments
                graphicsObjects matlab.graphics.primitive.Data
            end
            for ii = 1:numel(graphicsObjects)
                try %#ok<TRYNC>
                    bh = hggetbehavior(graphicsObjects(ii),'DataCursor');
                    bh.Enable = 0;
                end
            end
        end

        function rowNums = replaceDataTipRowLabel(responseObject,labelToFind,newLabel)
            dataTipRows = responseObject.DataTipTemplate.DataTipRows;
            changeLabel = contains({dataTipRows.Label},labelToFind);
            if any(changeLabel)
                dataTipRows(changeLabel).Label = newLabel;
                responseObject.DataTipTemplate.DataTipRows = dataTipRows;
            end
            rowNums = find(changeLabel);
        end

        function rowNums = replaceDataTipRowValue(responseObject,labelToFind,newValue)
            dataTipRows = responseObject.DataTipTemplate.DataTipRows;
            changeLabel = contains({dataTipRows.Label},labelToFind);
            if any(changeLabel)
                dataTipRows(changeLabel).Value = newValue;
                responseObject.DataTipTemplate.DataTipRows = dataTipRows;
            end
            rowNums = find(changeLabel);
        end

       function idx = findDataTipRowIndexByLabel(responseObject,labelToFind,optionalArguments)
            arguments
                responseObject
                labelToFind
                optionalArguments.FindExactMatch = true
            end
            dataTipRows = responseObject.DataTipTemplate.DataTipRows;
            if optionalArguments.FindExactMatch
            idx = find(strcmp({dataTipRows.Label},labelToFind));
            else
                idx = find(contains({dataTipRows.Label},labelToFind));
            end
        end

        function y = scaledInterp1(xValues,yValues,xSamples,xScale,yScale)
            % Safely interpolate data with linear/log scaling
            arguments
                xValues (:,1) double {mustBeNonempty}
                yValues (:,1) double {mustBeNonempty}
                xSamples (:,1)
                xScale (1,1) string {mustBeMember(xScale,["linear";"log"])} = "linear"
                yScale (1,1) string {mustBeMember(yScale,["linear";"log"])} = "linear"
            end
            controllib.chart.internal.utils.validators.mustBeSize(yValues,size(xValues));
            if isempty(xSamples)
                y = [];
                return;
            else
                y = NaN(size(xSamples));
            end
            validSamples = true(size(xSamples));
            % Convert x to log scale if needed
            if xScale == "log"
                inp = xValues > 0;
                xValues = xValues(inp);
                yValues = yValues(inp);
                xValues = log10(xValues);
                validSamples = validSamples & xSamples > 0;
                xSamples = log10(xSamples);
            end
            % Convert y to log scale if needed
            if yScale == "log"
                inp = yValues > 0;
                xValues = xValues(inp);
                yValues = yValues(inp);
                yValues = log10(yValues);
            end
            % Filter out invalid values
            ind = isnan(xValues) | isnan(yValues) | isinf(xValues) | isinf(yValues);
            xValues = xValues(~ind);
            yValues = yValues(~ind);
            validSamples = validSamples & ~isnan(xSamples) & ~isinf(xSamples);
            % Ensure x values are unique
            [~,ind] = unique(xValues,'stable');
            xValues = xValues(ind);
            yValues = yValues(ind);
            % Interpolate
            if any(validSamples) && ~isempty(xValues)
                if isscalar(yValues)
                    y(validSamples) = yValues;
                else
                    y(validSamples) = interp1(xValues,yValues,xSamples(validSamples));
                end
            end
            % Convert back if needed
            if yScale == "log"
                y = 10.^y;
            end
        end  

        function d = scaledProject2(xValues,yValues,dValues,point,xLim,yLim,xScale,yScale,optionalInputs)
            % Safely project data with linear/log scaling
            arguments
                xValues (:,1) double {mustBeNonempty}
                yValues (:,1) double {mustBeNonempty}
                dValues (:,1) double {mustBeNonempty}
                point (2,1) double
                xLim (1,2) double = [-1 1]
                yLim (1,2) double = [-1 1]
                xScale (1,1) string {mustBeMember(xScale,["linear";"log"])} = "linear"
                yScale (1,1) string {mustBeMember(yScale,["linear";"log"])} = "linear"
                optionalInputs.Interpolate (1,1) logical = true
            end
            controllib.chart.internal.utils.validators.mustBeSize(yValues,size(xValues));
            controllib.chart.internal.utils.validators.mustBeSize(dValues,size(xValues));
            if isscalar(dValues) % quick exit for degenerate case
                d = dValues;
                return;
            end
            switch xScale
                case "linear"
                    point(1) = (point(1)-xLim(1))/(xLim(2)-xLim(1));
                    xValues = (xValues-xLim(1))/(xLim(2)-xLim(1));
                case "log"
                    point(1) = (log10(point(1))-log10(xLim(1)))/(log10(xLim(2))-log10(xLim(1)));
                    xValues = (log10(xValues)-log10(xLim(1)))/(log10(xLim(2))-log10(xLim(1)));
            end
            switch yScale
                case "linear"
                    point(2) = (point(2)-yLim(1))/(yLim(2)-yLim(1));
                    yValues = (yValues-yLim(1))/(yLim(2)-yLim(1));
                case "log"
                    point(2) = (log10(point(2))-log10(yLim(1)))/(log10(yLim(2))-log10(yLim(1)));
                    yValues = (log10(yValues)-log10(yLim(1)))/(log10(yLim(2))-log10(yLim(1)));
            end
            % Project current point onto line segments.
            pointProj = zeros(2,length(dValues)-1);
            xInterp = zeros(size(dValues));
            for ii = 1:length(dValues)-1
                p1 = [xValues(ii);yValues(ii)];
                p2 = [xValues(ii+1);yValues(ii+1)];
                v = p2-p1;
                pointProj(:,ii) = p1+(point-p1)'*v/(v'*v)*v;
                if v(1) == 0 && v(2) == 0 %points overlap
                    x = 1;
                elseif v(1) == 0 %vertical
                    x = (pointProj(2,ii)-p1(2))/v(2);
                else
                    x = (pointProj(1,ii)-p1(1))/v(1);
                end
                xInterp(ii) = max(min(x,1),0);
                pointProj(:,ii) = p1+v*xInterp(ii);
            end
            % Find minimum distance of projected points
            diff = point-pointProj;
            dist = diff(1,:).^2+diff(2,:).^2;
            [~,idx] = min(dist);
            % Interpolate data to minimum wrapped projected point.
            if optionalInputs.Interpolate
                d = (1-xInterp(idx))*dValues(idx)+xInterp(idx)*dValues(idx+1);
            else
                d = dValues(idx);
            end
        end
    end

    %% Private methods
    methods(Access = private)
        function validateCharacteristicType(this,characteristicType)
            mustBeMember(characteristicType,this.CharacteristicTypes);
        end
        
        function validateVisibilitySize(this,visibility,type)
            switch type
                case 'ColumnVisible'
                    expectedVisible = this.ColumnVisible;
                case 'RowVisible'
                    expectedVisible = this.RowVisible;
                case 'ArrayVisible'
                    expectedVisible = this.ArrayVisible;
            end
            controllib.chart.internal.utils.validators.mustBeSize(visibility,size(expectedVisible));
        end
    
        function cbResponseGraphicsObjectsStyleChanged(this,ed,response)
            arguments
                this controllib.chart.internal.view.wave.BaseResponseView
                ed controllib.chart.internal.utils.GenericEventData
                response controllib.chart.internal.foundation.BaseResponse
            end
            propertyChanged = ed.Data.PropertyChanged;
            if strcmp(propertyChanged,'Marker')
                propertyChanged = 'MarkerStyle';
            end
            response.Style.(propertyChanged) = ed.Data.Value;
        end
    end

    methods (Access = protected)
       function plotRowIdx = computePlotRowIdx(this)
            plotRowIdx = this.Response.ResponseData.PlotOutputIdx;

            if isempty(plotRowIdx)
                plotRowIdx = 1:this.Response.NRows;
            end
        end

        function plotColumnIdx = computePlotColumnIdx(this)
             plotColumnIdx = this.Response.ResponseData.PlotInputIdx;
 
            if isempty(plotColumnIdx)
                plotColumnIdx = 1:this.Response.NColumns;
            end
        end
    end

    %% Private sealed methods
    methods (Sealed,Access=private)
        function validateAxesSubGridSize(this,ax,subGridSize)
            if ~isempty(ax)
                nRows = 1;
                nCols = 1;
                for ii = 1:length(this)
                    nRows = max(nRows,this(ii).Response.NRows);
                    nCols = max(nCols,this(ii).Response.NColumns);
                end
                mustBeGreaterThanOrEqual(size(ax,1),nRows*subGridSize(1));
                mustBeGreaterThanOrEqual(size(ax,2),nCols*subGridSize(2));
            end
        end

        function nameLabel = getNameLabel(this,ka)
            nameLabel = this.Response.Name;
            if this.Response.NResponses > 1
                s = this.Response.ArrayDim;
                if s(end) == 1
                    s = s(1:end-1);
                end
                if s(1) == 1
                    s = s(2:end);
                end
                makeArray = isscalar(s);
                if makeArray
                    s = [s 1];
                end
                sc = cell(1,length(s));
                [sc{:}] = ind2sub(s,ka);
                if makeArray
                    sc = sc(end-1);
                end                
                nameLabel = nameLabel + "(:,:,";
                for k = 1:length(sc)-1
                    nameLabel = nameLabel + sc{k} + ",";
                end
                nameLabel = nameLabel + sc{end} + ")";
            end
        end
    end

    %% Static private methods
    methods (Static,Access = private)
        function hScatters = createScatterObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hScatters = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Scatter');
            set(hScatters,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    SizeData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hLines = createLineObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hLines = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Line');
            set(hLines,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hStairs = createStairObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hStairs = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Stair');
            set(hStairs,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hBars = createBarObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hBars = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Bar');
            set(hBars,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hConstantLines = createConstantLineObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hConstantLines = createArray([nRows nColumns nArray],'matlab.graphics.chart.decoration.ConstantLine');
            set(hConstantLines,...
                    Parent_I=[],...
                    Serializable='off',...
                    Value=NaN,...
                    Layer='bottom',...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hPatches = createPatchObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hPatches = createArray([nRows nColumns nArray],'matlab.graphics.primitive.Patch');
            set(hPatches,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hConstantRegions = createConstantRegionObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hConstantRegions = createArray([nRows nColumns nArray],'matlab.graphics.chart.decoration.ConstantRegion');
            set(hConstantRegions,...
                    Parent_I=[],...
                    Serializable='off',...
                    Value=[NaN NaN],...
                    Layer='bottom',...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hStems = createStemObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = ''
                optionalInputs.LegendDisplay = 'off';
            end
            hStems = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Stem');
            set(hStems,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay=optionalInputs.LegendDisplay,...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility,...
                    DisplayName=optionalInputs.DisplayName);
        end

        function hRectangles = createRectangleObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = '' %Not used, rectangle has no legend entry
                optionalInputs.LegendDisplay = 'off'; %Not used, rectangle has no legend entry
            end
            hRectangles = createArray([nRows nColumns nArray],'matlab.graphics.primitive.Rectangle');
            set(hRectangles,...
                    Parent_I=[],...
                    Serializable='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
        end

        function hText = createTextObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
                optionalInputs.DisplayName = '' %Not used, text has no legend entry
                optionalInputs.LegendDisplay = 'off'; %Not used, text has no legend entry
            end
            hText = createArray([nRows nColumns nArray],'matlab.graphics.primitive.Text');
            set(hText,...
                    Parent_I=[],...
                    Serializable='off',...
                    Position=[NaN,NaN,0],...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
        end
    end

    %% Hidden Methods
    methods (Hidden)
        function createResponseDataTips(this)
            % Create data tip for all lines
            if ~this.IsResponseDataTipsCreated
                for ka = 1:this.Response.NResponses
                    % Name Data Tip Row
                    nameDataTipRow = getNameDataTipRow(this,ka);

                    for kr = 1:this.Response.NRows
                        for kc = 1:this.Response.NColumns
                            % I/O row
                            ioDataTipRow = getIODataTipRow(this,kc,kr);

                            % Custom Data Tip Row
                            customDataTipRows = getCustomDataTipRows(this,kr,kc,ka);

                            % Call subclass implementation to create data
                            % tips
                            % if isempty(ioDataTipRow)
                            %     createResponseDataTips_(this,kr,kc,ka,...
                            %         nameDataTipRow,customDataTipRows);
                            % else
                            createResponseDataTips_(this,kr,kc,ka,...
                                nameDataTipRow,ioDataTipRow,customDataTipRows);
                            % end
                        end
                    end
                end

                for k = 1:length(this.Characteristics)
                    if this.Characteristics(k).IsInitialized
                        createDataTips(this.Characteristics(k));
                    end
                end

                this.IsResponseDataTipsCreated = true;
            end            
        end

        function allHandles = qeGetAllGraphicsObjects(this,rowIndex,columnIndex,arrayIndex)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            allHandles = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = 1:length(rowIndex)
                for ki = 1:length(columnIndex)
                    for ka = 1:length(arrayIndex)
                        responseObjects = getResponseObjects(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        if ~isempty(responseObjects{1})
                            allHandles{ko,ki,ka} = cat(3,allHandles{ko,ki,ka},responseObjects{1});
                        end
                        supportingObjects = getSupportingObjects(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        if ~isempty(supportingObjects{1})
                            allHandles{ko,ki,ka} = cat(3,allHandles{ko,ki,ka},supportingObjects{1});
                        end
                        charMarkers = getCharacteristicMarkers(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        if ~isempty(charMarkers{1})
                            allHandles{ko,ki,ka} = cat(3,allHandles{ko,ki,ka},charMarkers{1});
                        end
                        charResponseObjects = getCharacteristicResponseObjects(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        if ~isempty(charResponseObjects{1})
                            allHandles{ko,ki,ka} = cat(3,allHandles{ko,ki,ka},charResponseObjects{1});
                        end
                        charSupportingObjects = getCharacteristicSupportingObjects(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        if ~isempty(charSupportingObjects{1})
                            allHandles{ko,ki,ka} = cat(3,allHandles{ko,ki,ka},charSupportingObjects{1});
                        end
                    end
                end
            end
        end

        function characteristicObjects = qeGetCharacteristic(this,type)
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                type (:,1) string = this.CharacteristicTypes
            end
            characteristicObjects = getCharacteristic(this,type);
        end

        function responseObjects = qeGetResponseObjects(this,rowIndex,columnIndex,arrayIndex)
            % qeGetResponseLines returns the lines for the response (with
            % input, output and array channels specified).
            %
            %   responseLines = qeGetResponseLines(response,outputIndex,inputIndex,arrayIndex);
            %       outputIndex, inputIndex, arrayIndex can be vector
            %       responseLines is returned as a cell array of all lines
            %       for the response.
            %
            %   responseLines = qeGetResponseLines(response);
            %       responseLines is returned as a cell array of all lines
            %       for all input, output, and array channels for the response.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            responseObjects = getResponseObjects(this,rowIndex,columnIndex,arrayIndex);
        end
        
        function supportingObjects = qeGetSupportingObjects(this,rowIndex,columnIndex,arrayIndex)
            % qeGetResponseLines returns the lines for the response (with
            % input, output and array channels specified).
            %
            %   responseLines = qeGetResponseLines(response,outputIndex,inputIndex,arrayIndex);
            %       outputIndex, inputIndex, arrayIndex can be vector
            %       responseLines is returned as a cell array of all lines
            %       for the response.
            %
            %   responseLines = qeGetResponseLines(response);
            %       responseLines is returned as a cell array of all lines
            %       for all input, output, and array channels for the response.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            supportingObjects = getSupportingObjects(this,rowIndex,columnIndex,arrayIndex);
        end

        function charMarkers = qeGetCharacteristicMarkers(this,rowIndex,columnIndex,arrayIndex)
            % qeGetCharacteristicMarkers returns the markers for all the
            % visible characteristics on the response (with input, output
            % and array channels specified).
            %
            %   charMarkers = qeGetCharacteristicMarkers(response,outputIndex,inputIndex,arrayIndex);
            %       outputIndex, inputIndex, arrayIndex are scalar values
            %       charMarkers is returned as an array of all visible characteristics.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            charMarkers = getCharacteristicMarkers(this,rowIndex,columnIndex,arrayIndex);
        end

        function charObjects = qeGetCharacteristicResponseObjects(this,rowIndex,columnIndex,arrayIndex)
            % qeGetCharacteristicLines returns the response lines for all the
            % visible characteristics on the response (with input, output
            % and array channels specified).
            %
            %   charLines = qeGetCharacteristicLines(response,outputIndex,inputIndex,arrayIndex);
            %       outputIndex, inputIndex, arrayIndex are scalar values
            %       charLines is returned as an array of all visible characteristics.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            charObjects = getCharacteristicSupportingObjects(this,rowIndex,columnIndex,arrayIndex);
        end

        function charObjects = qeGetCharacteristicSupportingObjects(this,rowIndex,columnIndex,arrayIndex)
            % qeGetCharacteristicLines returns the supporting lines for all the
            % visible characteristics on the response (with input, output
            % and array channels specified).
            %
            %   charLines = qeGetCharacteristicLines(response,outputIndex,inputIndex,arrayIndex);
            %       outputIndex, inputIndex, arrayIndex are scalar values
            %       charLines is returned as an array of all visible characteristics.
            arguments
                this (1,1) controllib.chart.internal.view.wave.BaseResponseView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            charObjects = getCharacteristicSupportingObjects(this,rowIndex,columnIndex,arrayIndex);
        end

        function response = qeGetResponse(this)
            response = getResponse(this.Response);
        end

        function registerCharacteristicView(this,characteristicView)
            this.Characteristics = [this.Characteristics; characteristicView];
        end

        function updateLegendObjectOnThemeChange(this,theme)
            % updateLegendObjectOnThemeChanged uses the theme to set RGB
            % color values on the legend objects if semantic colors are
            % used for the response style.

            % This is needed since the legend objects are unparented, and
            % always use the RGB value of the light (default) theme.
            arguments
                this
                theme matlab.graphics.theme.GraphicsTheme
            end
            legendObjects = getLegendObjects(this);
            for k = 1:length(legendObjects)
                if isprop(legendObjects(k),'Color') && strcmp(this.Response.Style.ColorMode,"semantic")
                    semanticColor = this.Response.Style.SemanticColor;
                    rgbColor = matlab.graphics.internal.themes.getAttributeValue(theme,semanticColor);         
                    legendObjects(k).Color = rgbColor;
                end
                if isprop(legendObjects(k),'FaceColor') && strcmp(this.Response.Style.FaceColorMode,"semantic")
                    semanticColor = this.Response.Style.SemanticFaceColor;
                    rgbColor = matlab.graphics.internal.themes.getAttributeValue(theme,semanticColor);         
                    legendObjects(k).FaceColor = rgbColor;
                end
                if isprop(legendObjects(k),'EdgeColor') && strcmp(this.Response.Style.EdgeColorMode,"semantic")
                    semanticColor = this.Response.Style.SemanticEdgeColor;
                    rgbColor = matlab.graphics.internal.themes.getAttributeValue(theme,semanticColor);         
                    legendObjects(k).EdgeColor = rgbColor;
                end
            end
        end
    end
end