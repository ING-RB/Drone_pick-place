% Displayer for request queue objects

% Copyright 2013-2021 The MathWorks, Inc.
classdef (Hidden) FevalQueueDisplayer < parallel.internal.display.AbstractDisplayer
    properties (Constant, GetAccess = private)
        VectorTableColumns = { ...
        % 'Title',    'Resizeable', 'MinimumWidth'
            'Number Queued',  true, length('Number Queued'); ...
            'Number Running', true, length('Number Running'); ...
                   }
    end

    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
        DisplayItemFactory
    end
    methods
        function obj = FevalQueueDisplayer()
            obj@parallel.internal.display.AbstractDisplayer(...
                'parallel.FevalQueue', 'parallel.FevalQueue');
            obj.DisplayHelper = parallel.internal.display.DisplayHelper(...
                numel('Function'));
            obj.DisplayItemFactory = parallel.internal.display.DisplayableItemBaseFactory(...
                obj.DisplayHelper);
        end
    end
    methods (Access = protected)
        function doSingleDisplay(obj, toDisp)
            if ~isvalid(toDisp) || ~hIsValid(toDisp)
                disp(getString(message('MATLAB:parallel:future:DeletedObject')));
                return
            end

            docLink = obj.formatDocLink(class(toDisp));

            displayWithPropsLabel = getString(...
                message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_SCALAR_WITH_PROPS', docLink));

            obj.DisplayHelper.displayMainHeading(...
                '%s \n', displayWithPropsLabel);
            obj.DisplayHelper.displayProperty('QueuedFutures', toDisp.QueuedFutures);
            obj.DisplayHelper.displayProperty('RunningFutures', toDisp.RunningFutures);
        end

        function doVectorDisplay(obj, toDisp)
            import parallel.internal.display.AbstractDisplayer
            import parallel.internal.fevalqueue.FevalQueueDisplayer

            columns = FevalQueueDisplayer.VectorTableColumns;
            tableData = cell(numel(toDisp), size(columns, 1));
            for ii = 1:numel(toDisp)
                if isvalid(toDisp(ii))
                    [tableData{ii, :}] = iGetDisplayProperties(toDisp(ii));
                else
                    tableData(ii, :) = {AbstractDisplayer.DeletedString, '', ''};
                end
            end
            obj.DisplayHelper.displayDimensionHeading(...
                size(toDisp), obj.formatDocLink(class(toDisp)));
            obj.DisplayHelper.displayTable(...
                columns, tableData, obj.DisplayHelper.DisplayIndexColumn);
        end
    end

end

function [nq, nr] = iGetDisplayProperties(Q)
    nq = numel(Q.QueuedFutures);
    nr = numel(Q.RunningFutures);
end
