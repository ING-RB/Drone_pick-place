classdef MLTableDataModel < internal.matlab.legacyvariableeditor.MLArrayDataModel & internal.matlab.legacyvariableeditor.TableDataModel
    %MLTableDATAMODEL
    %   MATLAB Cell Array Data Model

    % Copyright 2013-2014 The MathWorks, Inc.
    
    events
        MetaDataChanged;
    end

    methods(Access='public')
        % Constructor
        function this = MLTableDataModel(name, workspace)
            this@internal.matlab.legacyvariableeditor.MLArrayDataModel(name, workspace);
        end

        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            currentData = this.Data;
            data = newData;

            % Detect a property change
            if isequal(size(currentData),size(newData)) && ~isequal(currentData,newData)
                [I,J] = this.doCompare(newData);
                if isempty(I) && isempty(J)
                    this.Data = newData;

                    propNames = fieldnames(currentData.Properties);
                    for i=1:length(propNames)
                        if ~isequal(currentData.Properties.(propNames{i}), newData.Properties.(propNames{i}))
                            changeEventData = internal.matlab.legacyvariableeditor.MetaDataChangeEventData;
                            changeEventData.Property = propNames{i};
                            changeEventData.IsTypeChange = false;
                            changeEventData.OldValue = currentData.Properties.(propNames{i});
                            changeEventData.NewValue = newData.Properties.(propNames{i});
                            this.notify('MetaDataChanged',changeEventData);
                        end
                    end

                    return;
                end
            elseif isequal(size(currentData),size(newData)) && isequal(currentData,newData)
                % There seems to be a bug in isequal for tables where type
                % changes in properties aren't flagged as differences, we
                % will try and detect this
                [I,J] = this.doCompare(newData);
                foundTypeChange = false;
                foundDatetimeChange = false;
                hasDateTimes = ~isempty(isdatetime(currentData(:,1:end)));
                if (isempty(I) && isempty(J)) || hasDateTimes
                    propNames = currentData.Properties.VariableNames;
                    for i=1:length(propNames)
                        if ~strcmp(class(currentData.(propNames{i})), class(newData.(propNames{i})))
                            this.Data = newData;
                            foundTypeChange = true;

                            changeEventData = internal.matlab.legacyvariableeditor.MetaDataChangeEventData;
                            changeEventData.Property = propNames{i};
                            changeEventData.IsTypeChange = true;
                            changeEventData.OldValue = class(currentData.(propNames{i}));
                            changeEventData.NewValue = class(newData.(propNames{i}));
                            this.notify('MetaDataChanged',changeEventData);
                        end
                        
                        if isa(newData.(propNames{i}), 'datetime')
                            currentFormat   = currentData.(propNames{i}).Format;
                            currentTimeZone = currentData.(propNames{i}).TimeZone; 
                            newFormat       = newData.(propNames{i}).Format;
                            newTimeZone     = newData.(propNames{i}).TimeZone;
                            if ~strcmp(currentFormat, newFormat) || ~strcmp(currentTimeZone, newTimeZone)
                                this.Data = newData;
                                foundDatetimeChange = true;
                            end
                        end
                        
                    end                 
                    %handle the RowTime format change condition, g1610416
                    %This is needed because changes to the RowTimes format aren't picked up by the isequal() check above.
                    if isprop(currentData.Properties, 'RowTimes') && isprop(newData.Properties, 'RowTimes') && ~strcmp(currentData.Properties.RowTimes.Format, newData.Properties.RowTimes.Format)
                        this.Data = newData;
                        changeEventData = internal.matlab.legacyvariableeditor.MetaDataChangeEventData;
                        changeEventData.Property = 'RowTimes';
                        changeEventData.IsTypeChange = false;
                        changeEventData.OldValue = currentData.Properties.('RowTimes');
                        changeEventData.NewValue = newData.Properties.('RowTimes');
                        this.notify('MetaDataChanged',changeEventData);
                    end  
                    
                    % Return if a type change was found
                    if foundTypeChange || foundDatetimeChange
                        % Force a data update because the data itself may
                        % have changed if it's type has changed
                        eventdata = internal.matlab.legacyvariableeditor.DataChangeEventData;
                        eventdata.Range = [];
                        eventdata.Values = [];

                        this.notify('DataChange',eventdata);
                        return;
                    end                 
                end
            end

            % No type or property changes found so call the superclass
            % updateData method to send the actual data change
            data = this.updateData@internal.matlab.legacyvariableeditor.MLArrayDataModel(varargin{:});
        end
    end %methods
    
    methods(Access='protected')
        function [I,J] = doCompare(this, newData)
            % table setdiff doesn't work for cell columns unless they're cellstrs
            c = varfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), this.Data, 'OutputFormat', 'cell');
            cNew = varfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), newData, 'OutputFormat', 'cell');

            % If we have cell columns OR if the table variable names have changed
            % don't bother trying to figure out the differences just assume everything changed
            colNameChanged = ~isempty(setdiff(this.Data.Properties.VariableNames, newData.Properties.VariableNames));
            
            if any([c{:}]) || any([cNew{:}]) || colNameChanged
                [I,J] = meshgrid(1:height(this.Data),1:width(this.Data)); 
            else
                [~, I] = setdiff(this.Data, newData);
                if length(I) == 1
                    [~,J] = find(cellfun(@(a,b) ~isequal(a,b), table2cell(this.Data(I,:)), table2cell(newData(I,:))));
                    if length(J) > 1
                        [I,J] = meshgrid(I,J); 
                    end
                else
                    J = 1:width(this.Data);
                    [I,J] = meshgrid(I,J); 
                end
            end
        end
    end
end
