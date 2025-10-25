classdef CategoricalViewModel < internal.matlab.variableeditor.ArrayViewModel
    % CategoricalViewModel
    % Categorical variables ViewModel

    % Copyright 2013-2021 The MathWorks, Inc.

    % Public Abstract Methods
    properties (SetObservable=true, SetAccess='protected', Transient)
        TableMetaDataChangedListener;
    end

    properties (Constant)
        NEWLINEDISPLAYCHAR = matlab.internal.display.getNewlineCharacter(newline);
        TABDISPLAYCHAR = char(8594);
    end
    
    methods(Access='public')
        % Constructor
        function this = CategoricalViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
        end
        
        % Returns the categories for the categorical variable.
        function c = getCategories(this, truncateCats)
            arguments
                this
                truncateCats logical = true;
            end
            c = categories(this.DataModel.getData());
            
            % Limit the number of categories displayed, otherwise we
            % hit OutOfMemory errors
            if truncateCats
                c(internal.matlab.datatoolsservices.FormatDataUtils.MAX_CATEGORICALS:end) = [];
            end
        end
        
        % Returns true if the categorical variable is protected, and false
        % if it is not.  (Protected categorical variables cannot have new
        % categories added to them).
        function p = isProtected(this)
            p = isprotected(this.DataModel.getData());
        end     
        
         % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.TableMetaDataChangedListener)
                delete(this.TableMetaDataChangedListener);
                this.TableMetaDataChangedListener = [];
            end          
        end

        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            data = this.getData(startRow,endRow,startColumn,endColumn);
            [renderedData, renderedDims] = internal.matlab.variableeditor.CategoricalViewModel.getParsedCategoricalData(data);     
        end

        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end
    end

    methods(Static)
        function [renderedData, renderedDims] = getParsedCategoricalData(data)

            renderedData = string(data);
            renderedData(ismissing(renderedData)) = "<undefined>";

            % Replace newlines and tabs that may exist within the
            % categorical name with the knuckle character/forward arrow for
            % display
            newlineDisplayChar = internal.matlab.variableeditor.CategoricalViewModel.NEWLINEDISPLAYCHAR;
            tabDisplayChar = internal.matlab.variableeditor.CategoricalViewModel.TABDISPLAYCHAR;

            renderedData = replace(renderedData,{newline, sprintf('\t')},{newlineDisplayChar, tabDisplayChar});

            renderedDims = size(renderedData);
        end
    end
    
    methods(Access='protected')
        function initListeners(this)
            this.TableMetaDataChangedListener = event.listener(this.DataModel,'TableMetaDataChanged',@(es,ed) this.notify('TableMetaDataChanged', ed));
        end
    end
end
