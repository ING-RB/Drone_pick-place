% Displayer for parallel.pool.Constant objects

% Copyright 2015-2021 The MathWorks, Inc.

classdef ( Hidden ) PoolConstantDisplayer < parallel.internal.display.AbstractDisplayer
    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
        DisplayItemFactory
    end
    
    properties (Constant, GetAccess = private)
        VectorDisplayProps = {'Value'};
        VectorTableColumns = { ...
            % 'Title',    'Resizeable', 'MinimumWidth'
            'Value',         true,         length('Value'); ...
        }
    end    
    
    methods
        function obj = PoolConstantDisplayer()
            obj@parallel.internal.display.AbstractDisplayer(...
                'parallel.pool.Constant', 'parallel.pool.Constant');
            obj.DisplayHelper = parallel.internal.display.DisplayHelper(...
                numel('Value'));
            obj.DisplayItemFactory = parallel.internal.display.DisplayableItemBaseFactory(...
                obj.DisplayHelper);
        end
    end
    methods (Access = protected)
        function doSingleDisplay(obj, toDisp)
            if ~iIsDisplayable(toDisp)
                disp(getString(message('MATLAB:parallel:constant:InvalidConstant')));
                return;
            end
            
            docLink = obj.formatDocLink(class(toDisp));
            displayWithPropsLabel = getString(...
                message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_SCALAR_WITH_PROPS', docLink));
            obj.DisplayHelper.displayMainHeading(...
                '%s \n', displayWithPropsLabel);
            
            obj.displaySpecificItems(toDisp);
        end
        
        function doVectorDisplay(obj, toDisp)            
            import parallel.internal.constant.PoolConstantDisplayer
            
            tableData = cell(numel(toDisp), size(PoolConstantDisplayer.VectorTableColumns, 1));         
            for ii = 1:numel( toDisp )
                if ~iIsDisplayable(toDisp(ii))
                    tableData(ii, :) = {getString(message('MATLAB:parallel:constant:InvalidConstant'))};
                else
                    tableData(ii, :) = {toDisp(ii).Value};
                end
            end
            obj.DisplayHelper.displayDimensionHeading(size(toDisp), obj.formatDocLink(class(toDisp)));
            obj.DisplayHelper.displayTable(PoolConstantDisplayer.VectorTableColumns, tableData, obj.DisplayHelper.DisplayIndexColumn);

        end
        
        function displaySpecificItems(obj, toDisp)
            % Gets the specified properties from the toDisp object and
            % displays them.
            [poolConstantPropertyMap, propNames] = toDisp.hGetDisplayItems(obj.DisplayItemFactory);
            
            for ii = 1:numel(propNames)
                displayValue = poolConstantPropertyMap(propNames{ii});
                displayValue.displayInMATLAB(propNames{ii});
            end
        end
    end
end

function tf = iIsDisplayable(toDisp)
tf = isvalid(toDisp) && toDisp.hGetIsValidID();
end