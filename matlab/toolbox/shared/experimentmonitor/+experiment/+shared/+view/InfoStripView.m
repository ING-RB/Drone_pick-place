classdef InfoStripView < handle
    % InfoStripView  View for displaying names and values as two columns with 
        % multiple rows in a gridlayout, where the first column is the info
        % names and the second column the info values.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = private)
        % MainComponent (uigridlayout) Main grid layout holding all the
        % components.
        MainComponent

        InfoLabelNames

        % InfoLabels cell array of uilabels containing the info values to
        % be updated.
        InfoLabelValues

        % Model (experiment.shared.model.Model)
        % View-model used by this view to listen for updates.
        Model

        % Listeners  cell array of listeners on the model.
        Listeners
    end

    methods
        function this = InfoStripView(parent, model)
            this.Model = model;
            this.InfoLabelNames = dictionary(string.empty(), matlab.graphics.Graphics.empty());
            this.InfoLabelValues = dictionary(string.empty(), matlab.graphics.Graphics.empty());

            % Get a weak reference of the `this` object and create some
            % listeners.
            weakThis = matlab.lang.WeakReference(this);
            this.Listeners{end+1} = listener(this.Model, 'InfoUpdated', @(~, evtData) weakThis.Handle.onInfoUpdated(evtData));
            this.Listeners{end+1} = listener(this.Model, 'InfoAdded', @(~, evtData) weakThis.Handle.onInfoAdded(evtData));
            this.Listeners{end+1} = listener(this.Model, 'InfoDisplayNameWasSet', @(~, ~) weakThis.Handle.onInfoDisplayNameSet());

            this.MainComponent = uigridlayout(...
                parent, ...
                "RowHeight", {'fit'}, ...
                "ColumnWidth", {'0.5x', '0.5x'}, ...
                "Padding", [0,0,0,3],...
                "RowSpacing", 6, "ColumnSpacing", 0,...
                "Tag", "EXPERIMENT_INFOSTRIP_MAINCOMPONENT");
            
            this.populateFromModel();
        end

        function delete(this)
            for i = 1:length(this.Listeners)
                delete(this.Listeners{i});
            end
   
            delete(this.MainComponent);
        end
    end

    methods (Access = private)
        function addInfo(this, infoNames)
            numInfo = length(infoNames);

            this.MainComponent.RowHeight = repmat({'fit'}, 1,numInfo);

            infoDisplayNames = this.Model.InfoDisplayNameMap(infoNames);

            for i=1:numInfo
                 thisInfoName = infoNames(i);
                if ~this.InfoLabelNames.isKey(thisInfoName)
                    this.InfoLabelNames(thisInfoName) = uilabel(...
                        this.MainComponent,...
                        "Text", infoDisplayNames(i) + ":",...
                        "FontSize", iFontSizeInPixels(),...
                        "WordWrap","on",...
                        "Tag", "EXPERIMENT_INFOSTRIP_LABELNAME_" + upper(thisInfoName));
                    this.InfoLabelValues(thisInfoName) = uilabel(...
                        this.MainComponent,...
                        "Text", "",...
                        "FontSize", iFontSizeInPixels(),...
                        "WordWrap","on",...
                        "Tag", "EXPERIMENT_INFOSTRIP_LABELVALUE_" + upper(thisInfoName));
                end

                this.InfoLabelNames(thisInfoName).Layout.Row = i;
                this.InfoLabelValues(thisInfoName).Layout.Row = i;
            end
        end

        function updateInfo(this, infoNames, infoValues)
            infoValues = string(infoValues);
            for i=1:length(infoNames)
                lbl = this.InfoLabelValues(infoNames(i));
                lbl.Text = infoValues(i);
                this.InfoLabelValues(infoNames(i)) = lbl;
            end
        end

        function populateFromModel(this)
            % Create the Info rows.
            infoNames = this.Model.Info;
            if ~isempty(infoNames)
                this.addInfo(infoNames);

                infoNamesToUpdate = string.empty();
                infoValuesToUpdate = cell.empty();
                for i = 1:length(infoNames)
                    thisInfoData = this.Model.InfoData.(infoNames(i));
                    if ~isempty(thisInfoData)
                        infoNamesToUpdate(end+1) = infoNames(i);
                        infoValuesToUpdate{end+1} = thisInfoData(end);
                    end
                end

                this.updateInfo(infoNamesToUpdate, infoValuesToUpdate);
            end 
        end

        function onInfoAdded(this, evtData)
            infoNames = evtData.data.InfoNames;
            this.addInfo(infoNames);
        end

        function onInfoUpdated(this, evtData)
            infoNames = evtData.data.InfoNames;
            infoValues = evtData.data.InfoValues;

            this.updateInfo(infoNames, infoValues);
        end

        function onInfoDisplayNameSet(this)
            infoDisplayMap = this.Model.InfoDisplayNameMap;

            infoNames = keys(infoDisplayMap);
            infoDisplayNames = values(infoDisplayMap);
            numDisplayNames = length(infoNames);

            for i = 1:numDisplayNames
                lbl = this.InfoLabelNames(infoNames(i));
                lbl.Text = infoDisplayNames(i);
                this.InfoLabelNames(infoNames(i)) = lbl;
            end
        end
    end
end

function pixels = iFontSizeInPixels()
pixels = 12;
end
