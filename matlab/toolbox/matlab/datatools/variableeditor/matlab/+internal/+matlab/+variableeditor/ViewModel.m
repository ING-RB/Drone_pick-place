classdef ViewModel < internal.matlab.variableeditor.Variable & internal.matlab.variableeditor.EditableVariable & internal.matlab.variableeditor.ActionMixin
    % ViewModel
    % An abstract class defining the methods for a Variable View Model
    
    % Copyright 2013-2024 The MathWorks, Inc.
        
    % Property Definitions:

    % DataModel
    properties (SetObservable=true, SetAccess='protected', GetAccess='public')
        % DataModel Property
        DataModel;
    end

    properties (SetObservable=true, SetAccess='protected', GetAccess='public', Transient)
        DataChangeListeners;
    end
    
    properties (Dependent = false)
        viewID;
        viewType;
    end
    
    methods
        function storedValue = get.DataModel(this)
            storedValue = this.DataModel;
        end
        
        function set.DataModel(this, newValue)
            reallyDoCopy = ~isequal(this.DataModel, newValue);
            if reallyDoCopy
                this.DataModel = newValue;
            end
        end
    end
    
    % Cosntructor
    methods
        function this = ViewModel(dataModel,varargin)
            this.DataModel = dataModel;
            if (~isempty(dataModel))
                this.DataChangeListeners = event.listener(dataModel,'DataChange',@(e,d) this.handleDataChangedOnDataModel(e,d));                
            end
        end

        % Cleanup listeners on viewmodel delete
        function delete(this)
            if ~isempty(this.DataChangeListeners)
                delete(this.DataChangeListeners);
                this.DataChangeListeners = [];
            end
        end
    end
    
    % Private Methods
    methods(Access='protected')
        
        function handleDataChangedOnDataModel(this, ~ ,ed)
            this.notify('DataChange', ed);            
        end
    end
    
    % Public Abstract Methods
    methods(Access='public',Abstract=true)
        % getRenderedData
        varargout = getRenderedData(this,varargin);

        % isSelectable
        selectable = isSelectable(this);

        % isEditable
        editable = isEditable(this, varargin);
    end %methods

    % Public Methods
    methods(Access='public',Abstract=false)
        function [valueSummary, isMeta] = getValueSummaryData(this)
            [valueSummary, isMeta] = internal.matlab.variableeditor.ViewModel.getValueSummary(this.DataModel.Data);
        end
        
        function displaySize = getDisplaySize(this)
            import internal.matlab.datatoolsservices.FormatDataUtils;
            data = this.DataModel.Data;            
            displaySize = internal.matlab.datatoolsservices.FormatDataUtils.formatSize(data);
        end
    end
    
    % Public Static Methods
    methods(Static, Access='public')
        % Get variable summary information
        function [valueObject, isMeta] = getValueSummary(value)
            isMeta = false;
            try
                f = internal.matlab.datatoolsservices.FormatDataUtils;
                displayValue = f.formatSingleDataForMixedView(value);
                valueObject = displayValue{1};
                isMeta = f.isSummaryValue(value);
            catch
            end
        end
    end
    
end %classdef
