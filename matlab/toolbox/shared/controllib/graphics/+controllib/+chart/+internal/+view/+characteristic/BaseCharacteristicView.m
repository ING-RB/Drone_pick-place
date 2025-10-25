classdef (Abstract) BaseCharacteristicView < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & ...
        controllib.chart.internal.foundation.MixInListeners
    % Base class for characteristic markers

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Properties

    properties (SetAccess = protected)
        Visible (1,1) matlab.lang.OnOffSwitchState = false
        IsInitialized (1,1) logical = false
        Type (1,1) string = ""
        ResponseLineIdx (1,:) double = 1
    end

    properties (Hidden,GetAccess = protected,SetAccess = immutable)
        ResponseView
    end

    properties (Hidden,Dependent,GetAccess = protected,SetAccess = private)
        Response
    end

    properties (Access=private)
        GraphicsObjects (:,1) cell
    end

    %% Abstract methods
    methods(Abstract, Access = protected)
        build_(this);
        updateData(this,ko,ki,ka)
    end

    %% Constructor/destructor
    methods
        function this = BaseCharacteristicView(responseView,data)
            arguments
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
                data (1,1) controllib.chart.internal.data.characteristics.BaseCharacteristicData
            end
            this.ResponseView = responseView;
            this.Type = data.Type;
        end

        function delete(this)
            cellfun(@(x) delete(x),this.GraphicsObjects);
            unregisterListeners(this);
        end
    end

    %% Get/Set
    methods
        % Response
        function Response = get.Response(this)
            Response = this.ResponseView.Response;
        end
    end

    %% Public methods
    methods
        function updateStyle(this,style)
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                style (1,1) controllib.chart.internal.options.ResponseStyle
            end
            % updateStyle(this,Style)
            %
            %   Update style (Color, MarkerStyle, MarkerSize) of
            %   characterisitic marker objects.
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        % Set Marker Color
                        cMarkers = getMarkerObjects(this,ko,ki,ka);
                        styleValue = getValue(style,InputIndex=ki,OutputIndex=ko,ArrayIndex=ka);
                        sv = fieldnames(styleValue);
                        for ii = 1:length(sv)
                            if ~isprop(this.Response,sv{ii}) && ~strcmp(sv{ii},'CharacteristicsMarker')  && ~strcmp(sv{ii},'CharacteristicsMarkerSize')
                                styleValue = rmfield(styleValue,sv{ii});
                            end
                        end
                        for k = 1:numel(cMarkers{1})
                            cMarkers{1}(k).Marker = styleValue.CharacteristicsMarker;
                            if isprop(cMarkers{1}(k),'MarkerSize')
                                cMarkers{1}(k).MarkerSize = styleValue.CharacteristicsMarkerSize;
                            elseif isprop(cMarkers{1}(k),'SizeData')
                                cMarkers{1}(k).SizeData = styleValue.CharacteristicsMarkerSize^2;
                            end
                            if isfield(styleValue,'Color')
                                controllib.plot.internal.utils.setColorProperty(...
                                    cMarkers{1}(k),"MarkerEdgeColor",styleValue.Color);
                            elseif isfield(styleValue,'FaceColor')
                                controllib.plot.internal.utils.setColorProperty(...
                                    cMarkers{1}(k),"MarkerEdgeColor",styleValue.FaceColor);
                            end
                            if isfield(cMarkers{1}(k).UserData,'ValueOutsideLimits') && ...
                                    cMarkers{1}(k).UserData.ValueOutsideLimits
                                controllib.plot.internal.utils.setColorProperty(...
                                    cMarkers{1}(k),"MarkerFaceColor","--mw-graphics-backgroundColor-axes-primary");
                            else
                                if isfield(styleValue,'Color')
                                    controllib.plot.internal.utils.setColorProperty(...
                                        cMarkers{1}(k),"MarkerFaceColor",styleValue.Color);
                                elseif isfield(styleValue,'FaceColor')
                                    controllib.plot.internal.utils.setColorProperty(...
                                        cMarkers{1}(k),"MarkerFaceColor",styleValue.FaceColor);
                                end
                            end
                        end

                        rObjects = getResponseObjects(this,ko,ki,ka);
                        for k = 1:numel(rObjects{1})
                            if isprop(rObjects{1}(k),'Color')
                                if isfield(styleValue,'Color')
                                    styleColor = styleValue.Color;
                                elseif isfield(styleValue,'FaceColor')
                                    styleColor = styleValue.FaceColor;
                                else
                                    continue;
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
                                elseif isfield(styleValue,'Color')
                                    controllib.plot.internal.utils.setColorProperty(...
                                        rObjects{1}(k),["FaceColor","EdgeColor"],styleValue.Color);
                                end
                            elseif isprop(rObjects{1}(k),'MarkerEdgeColor')
                                if isfield(styleValue,'Color')
                                    controllib.plot.internal.utils.setColorProperty(...
                                        rObjects{1}(k),"MarkerEdgeColor",styleValue.Color);
                                elseif isfield(styleValue,'FaceColor')
                                    controllib.plot.internal.utils.setColorProperty(...
                                        rObjects{1}(k),"MarkerEdgeColor",styleValue.FaceColor);
                                end
                            end
                        end
                        updateStyle_(this,style,ko,ki,ka);
                    end
                end
            end
        end

        function setVisible(this,visible,optionalInputs)
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                visible (1,1) matlab.lang.OnOffSwitchState = this.Visible
                optionalInputs.InputVisible (1,:) logical = true(1,this.Response.NColumns)
                optionalInputs.OutputVisible (:,1) logical = true(this.Response.NRows,1)
                optionalInputs.ArrayVisible logical = true(this.Response.ArrayDim)
            end

            % Set visibility
            for kr = 1:this.Response.NRows
                for kc = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        visibleFlag = visible & optionalInputs.ArrayVisible(ka) & ...
                            optionalInputs.OutputVisible(kr) & optionalInputs.InputVisible(kc);
                        if ~isempty(this.Response.NominalIndex) && ka ~= this.Response.NominalIndex
                            visibleFlag = false;
                        end
                        cMarkers = getMarkerObjects(this,kr,kc,ka);
                        for ii = 1:numel(cMarkers{1})
                            cMarkers{1}(ii).Visible = visibleFlag;
                        end
                        rObjects = getResponseObjects(this,kr,kc,ka);
                        for ii = 1:numel(rObjects{1})
                            rObjects{1}(ii).Visible = visibleFlag;
                        end
                        sObjects = getSupportingObjects(this,kr,kc,ka);
                        for ii = 1:numel(sObjects{1})
                            sObjects{1}(ii).Visible = visibleFlag;
                        end
                    end
                end
            end
            this.Visible = visible;
        end

        function updateIODataTipRow(this)

        end
    end

    %% Sealed methods
    methods (Sealed)
        function build(this)
            if ~this.IsInitialized
                build_(this);
                this.IsInitialized = true;
            end
        end

        function update(this)
            if this.IsInitialized
                characteristicData = getCharacteristics(this.Response.ResponseData,this.Type);
                if characteristicData.IsDirty
                    compute(characteristicData);
                end
                for kr = 1:this.Response.NRows
                    for kc = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            updateData(this,kr,kc,ka);
                            updateDataByLimits(this,kr,kc,ka);
                            if this.IsInitialized
                                updateDataTips(this,kr,kc,ka);
                            end
                        end
                    end
                end
                updateStyle(this,this.Response.Style);
            end
        end

        function updateByLimits(this)
            if this.IsInitialized
                for kr = 1:this.Response.NRows
                    for kc = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            updateDataByLimits(this,kr,kc,ka);
                        end
                    end
                end
                updateStyle(this,this.Response.Style);
            end
        end

        function c = getMarkerObjects(this,rowIndex,columnIndex,arrayIndex)
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            c = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        if this.IsInitialized
                            c{ko,ki,ka} = getMarkerObjects_(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        else
                            c{ko,ki,ka} = matlab.graphics.primitive.Data.empty;
                        end
                    end
                end
            end
        end

        function r = getResponseObjects(this,rowIndex,columnIndex,arrayIndex)
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            r = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        if this.IsInitialized
                            r{ko,ki,ka} = getResponseObjects_(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        else
                            r{ko,ki,ka} = matlab.graphics.primitive.Data.empty;
                        end
                    end
                end
            end
        end

        function s = getSupportingObjects(this,rowIndex,columnIndex,arrayIndex)
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                rowIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NRows
                columnIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NColumns
                arrayIndex (1,:) double {mustBePositive,mustBeInteger} = 1:this.Response.NResponses
            end
            s = cell(length(rowIndex),length(columnIndex),length(arrayIndex));
            for ko = length(rowIndex):-1:1
                for ki = length(columnIndex):-1:1
                    for ka = length(arrayIndex):-1:1
                        if this.IsInitialized
                            s{ko,ki,ka} = getSupportingObjects_(this,rowIndex(ko),columnIndex(ki),arrayIndex(ka));
                        else
                            s{ko,ki,ka} = matlab.graphics.primitive.Data.empty;
                        end
                    end
                end
            end
        end
    end

    %% Protected methods (to be overridden in subclass if needed)
    methods (Access = protected)
        function updateDataByLimits(this,kr,kc,ka) %#ok<INUSD>

        end

        function updateDataTips(this,ko,ki,ka)
            % Create data tip for all lines
            % Name Data Tip Row
            nameDataTipRow = getNameDataTipRow(this,ka);
            % Custom Data Tip Row
            customDataTipRows = getCustomDataTipRows(this,ko,ki,ka);

            % Call subclass implementation to create data
            % tips
            updateDataTips_(this,ko,ki,ka,...
                nameDataTipRow,customDataTipRows);
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,customDataTipRows) %#ok<INUSD>

        end

        function updateStyle_(this,style,ko,ki,ka) %#ok<INUSD>

        end

        function c = getMarkerObjects_(this,ka,ko,ki) %#ok<INUSD>
            c = matlab.graphics.primitive.Data.empty;
        end

        function l = getSupportingObjects_(this,ka,ko,ki) %#ok<INUSD>
            l = matlab.graphics.primitive.Data.empty;
        end

        function p = getResponseObjects_(this,ka,ko,ki) %#ok<INUSD>
            p = matlab.graphics.primitive.Data.empty;
        end

        function nameRow = getNameDataTipRow(this,ka)
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
            nameRow = dataTipTextRow(getString(message('Controllib:plots:strResponse')),@(x) nameLabel);
        end
    end

    %% Protected sealed methods
    methods (Sealed,Access = protected)
        function hObjects = createGraphicsObjects(this,type,nRows,nColumns,nArray,optionalInputs)
            % Create an array of graphics objects
            arguments
                this (1,1) controllib.chart.internal.view.characteristic.BaseCharacteristicView
                type (1,1) string {mustBeMember(type,...
                    ["scatter";"line";"stair";"stem";"patch";"bar";...
                    "constantLine";"constantRegion";"rectangle"])}
                nRows (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                nColumns (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                nArray (1,1) double {mustBeInteger,mustBeNonnegative} = 1
                optionalInputs.Tag (1,:) char = ''
                optionalInputs.HitTest (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.PickableParts (1,:) char...
                    {mustBeMember(optionalInputs.PickableParts,{'visible','all','none'})} = 'visible'
                optionalInputs.HandleVisibility (1,:) char = 'on'
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
            end
            this.GraphicsObjects{end+1} = hObjects;
        end

        function customDataTipRows = getCustomDataTipRows(this,ko,ki,ka)
            if isempty(this.Response.DataTipInfo)
                customDataTipRows = matlab.graphics.datatip.DataTipTextRow.empty;
            else
                customDataTipInfo = this.Response.DataTipInfo{ka}(ko,ki);
                customDataTipLabels = fieldnames(customDataTipInfo);
                customDataTipRows = createArray([length(customDataTipLabels) 1],'matlab.graphics.datatip.DataTipTextRow');
                for k = 1:length(customDataTipLabels)
                    customDataTipRows(k) = dataTipTextRow(customDataTipLabels{k},...
                        @(x) customDataTipInfo.(customDataTipLabels{k}));
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static, Sealed, Access=protected)
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
            dataTipRows(changeLabel).Label = newLabel;
            responseObject.DataTipTemplate.DataTipRows = dataTipRows;
            rowNums = find(changeLabel);
        end

        function rowNums = replaceDataTipRowValue(responseObject,labelToFind,newValue)
            dataTipRows = responseObject.DataTipTemplate.DataTipRows;
            changeLabel = contains({dataTipRows.Label},labelToFind);
            dataTipRows(changeLabel).Value = newValue;
            responseObject.DataTipTemplate.DataTipRows = dataTipRows;
            rowNums = find(changeLabel);
        end

        function y = scaledInterp1(xValues,yValues,xSamples,xScale,yScale)
            % Safely interpolate data with linear/log scaling
            arguments
                xValues (:,1) double {mustBeNonempty}
                yValues (:,1) double {mustBeNonempty}
                xSamples (:,1) double
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

    %% Static private methods
    methods (Static,Access = private)
        function hScatter = createScatterObjects(nRows,nColumns,nArray,optionalInputs)
            arguments
                nRows
                nColumns
                nArray
                optionalInputs.Tag = ''
                optionalInputs.HitTest = matlab.lang.OnOffSwitchState(true)
                optionalInputs.PickableParts = 'visible'
                optionalInputs.HandleVisibility = 'on'
            end
            hScatter = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Scatter');
            set(hScatter,Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    SizeData=NaN,...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hLines = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Line');
            set(hLines,Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,....
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hStairs = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Stair');
            set(hStairs,Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hBars = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Bar');
            set(hBars,Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hConstantLines = createArray([nRows nColumns nArray],'matlab.graphics.chart.decoration.ConstantLine');
            set(hConstantLines,Parent_I=[],...
                    Serializable='off',...
                    Value=NaN,...
                    Layer='bottom',...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hPatches = createArray([nRows nColumns nArray],'matlab.graphics.primitive.Patch');
            set(hPatches,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hConstantRegions = createArray([nRows nColumns nArray],'matlab.graphics.chart.decoration.ConstantRegion');
            set(hConstantRegions,...
                    Parent_I=[],...
                    Serializable='off',...
                    Value=[NaN NaN],...
                    Layer='bottom',...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
            end
            hStems = createArray([nRows nColumns nArray],'matlab.graphics.chart.primitive.Stem');
            set(hStems,...
                    Parent_I=[],...
                    Serializable='off',...
                    XData=NaN,...
                    YData=NaN,...
                    LegendDisplay='off',...
                    Tag=optionalInputs.Tag,...
                    HitTest=optionalInputs.HitTest,...
                    PickableParts=optionalInputs.PickableParts,...
                    HandleVisibility = optionalInputs.HandleVisibility);
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
    end

    %% Hidden methods
    methods (Hidden)
        function createDataTips(this)
            if this.Visible
                for kr = 1:this.Response.NRows
                    for kc = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            updateDataTips(this,kr,kc,ka);
                        end
                    end
                end
            end
        end
    end
end