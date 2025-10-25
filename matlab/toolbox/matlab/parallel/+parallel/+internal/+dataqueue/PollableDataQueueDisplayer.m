% Displayer for PollableDataQueue objects

% Copyright 2024 The MathWorks, Inc.

classdef (Hidden) PollableDataQueueDisplayer < parallel.internal.display.AbstractDisplayer
    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
        DisplayItemFactory
    end

    properties (Constant, GetAccess = private)
        VectorDisplayProps = {'QueueLength', 'IsClosed'};
        VectorTableColumns = { ...
            % 'Title',    'Resizeable', 'MinimumWidth'
            'QueueLength',         false,         length('QueueLength'); ...
            'IsClosed',            false,         length('IsClosed');  
        }
    end 

    methods
        function obj = PollableDataQueueDisplayer()
            classToDisplay = 'parallel.pool.PollableDataQueue';
            obj@parallel.internal.display.AbstractDisplayer(...
                classToDisplay, classToDisplay);
            obj.DisplayHelper = parallel.internal.display.DisplayHelper(...
                numel('QueueLength'));
            obj.DisplayItemFactory = parallel.internal.display.DisplayableItemBaseFactory(...
                obj.DisplayHelper);
        end
    end

    methods (Access = protected)
        function doSingleDisplay(obj, toDisp)
            if ~isvalid(toDisp)
                disp(getString(message('parallel:lang:pool:DeletedObject')));
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
            import parallel.internal.dataqueue.PollableDataQueueDisplayer
            
            tableData = cell(numel(toDisp), size(PollableDataQueueDisplayer.VectorTableColumns, 1));         
            for ii = 1:numel( toDisp )
                tableData(ii, 1) = {toDisp(ii).QueueLength};
                tableData(ii, 2) = {toDisp(ii).IsClosed};
            end
            obj.DisplayHelper.displayDimensionHeading(size(toDisp), obj.formatDocLink(class(toDisp)));
            obj.DisplayHelper.displayTable(PollableDataQueueDisplayer.VectorTableColumns, tableData, obj.DisplayHelper.DisplayIndexColumn);
        end

        function displaySpecificItems(obj, toDisp)
            % Gets the specified properties from the toDisp object and
            % displays them.

            % Create an empty map to hold displayable PollableDataQueue properties
            poolPropertyMap = dictionary(string.empty(), parallel.internal.display.Default.empty());

            % Display order to put into propNames
            propNames = {'QueueLength', 'IsClosed'};

            poolPropertyMap("QueueLength") = obj.DisplayItemFactory.createDefaultItem(toDisp.QueueLength);
            poolPropertyMap("IsClosed") = obj.DisplayItemFactory.createDefaultItem(toDisp.IsClosed);

            for ii = 1:numel(propNames)
                displayValue = poolPropertyMap(propNames{ii});
                displayValue.displayInMATLAB(propNames{ii});
            end
        end
    end
end
