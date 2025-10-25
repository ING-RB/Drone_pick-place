% FutureDisplayer - displayer for parallel.Future items

% Copyright 2013-2021 The MathWorks, Inc.
classdef (Sealed) FutureDisplayer < parallel.internal.display.AbstractDisplayer
    properties (Constant, GetAccess = private)
        VectorTableColumns = { ...
        % 'Title',    'Resizeable', 'MinimumWidth'
            'ID',         true,         length('ID'); ...
            'State',      false,        length('finished (unread)'); ...
            'FinishDateTime', true,     length('FinishDateTime'); ...
            'Function',   true,         length('Function'); ...
            'Error',      false,        length('Error'); ...
                   }
    end
    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
        DisplayItemFactory
    end

    methods
        function obj = FutureDisplayer(varargin)
            if nargin == 0
                classToDisplay = 'parallel.Future';
            else
                classToDisplay = varargin{1};
            end

            obj@parallel.internal.display.AbstractDisplayer(...
                classToDisplay, classToDisplay);
            obj.DisplayHelper = parallel.internal.display.DisplayHelper(...
                numel('Function'));
            obj.DisplayItemFactory = parallel.internal.display.DisplayableItemBaseFactory(...
                obj.DisplayHelper);
        end
    end
    methods (Access = protected)
        function doSingleDisplay(obj, toDisp)
            if ~isvalid(toDisp)
                disp(getString(message('MATLAB:parallel:future:DeletedObject')));
                return
            end
            docLink = obj.formatDocLink(class(toDisp));

            displayWithPropsLabel = getString(...
                message('MATLAB:ObjectText:DISPLAY_AND_DETAILS_SCALAR_WITH_PROPS', docLink));

            obj.DisplayHelper.displayMainHeading(...
                '%s \n', displayWithPropsLabel);

            defaultItemNames = {'ID', 'Function', 'CreateDateTime', 'StartDateTime'};
            % datetimes need converting to char using the CHAR function.
            defaultItemCvt   = {@(x) x, @(x) x, @char, @char};
            defaultItemProperties = cellfun(@(name, cvt) cvt(toDisp.(name)), ...
                                            defaultItemNames, defaultItemCvt, ...
                                            'UniformOutput', false);
            defaultItemValues = obj.DisplayItemFactory.makeMultipleItems(...
                @createDefaultItem, defaultItemProperties);

            % We get the state string before any other mutable property
            % because once it reports 'finished', all other properties must
            % be final. Retrieving any other property first could result in
            % a race condition where we display a stale value as if it were
            % final.
            state = iGetStateString(toDisp);

            for ii = 1:numel(defaultItemNames)
                displayInMATLAB(defaultItemValues{ii}, defaultItemNames{ii});
            end

            % Running duration
            displayInMATLAB(obj.DisplayItemFactory.createDurationItem(...
                toDisp.RunningDuration), ...
                            'RunningDuration');

            % Show 'State'
            displayInMATLAB(obj.DisplayItemFactory.createDefaultItem(...
                state), 'State');

            % Show 'Error'
            if isa(toDisp.Error, 'MException')
                if ~toDisp.hHasParentProperty() || isempty(toDisp.Parent)
                    pool = [];
                else
                    pool = toDisp.Parent.Parent;
                end
                errorValue = obj.DisplayItemFactory.createRequestErrorItem(...
                    toDisp.Error, pool);
            else
                errorValue = obj.DisplayItemFactory.createDefaultItem(...
                    toDisp.Error);
            end
            errorValue.displayInMATLAB('Error');
        end
        function doVectorDisplay(obj, toDisp)
            import parallel.internal.future.FutureDisplayer
            import parallel.internal.display.AbstractDisplayer

            if all(~isvalid(toDisp))
                disp(getString(message('MATLAB:parallel:future:DeletedObject')));
                return
            end
            columns = FutureDisplayer.VectorTableColumns;
            tableData = cell(numel(toDisp), size(columns, 1));
            for ii = 1:numel(toDisp)
                currToDisp = toDisp(ii);
                if isvalid(currToDisp)
                    % State property must be accessed before any mutable
                    % property (see doSingleDisplay for more).
                    dataRow = {currToDisp.ID, ...
                               iGetStateString(currToDisp), ...
                               char(currToDisp.FinishDateTime), ...
                               currToDisp.Function, ...
                               iGetErrorVectorDisplayValue(currToDisp.Error)};
                else
                    dataRow = {'', AbstractDisplayer.DeletedString, '', '', ''};
                end
                tableData(ii, :) = dataRow;
            end
            % In the vector display we only want to display help for the common base class
            obj.DisplayHelper.displayDimensionHeading(...
                size(toDisp), obj.formatDocLink(class(toDisp)));
            obj.DisplayHelper.displayTable(...
                columns, tableData, obj.DisplayHelper.DisplayIndexColumn);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stateStr = iGetStateString(toDisp)
    stateStr = toDisp.State;
    if isequal(stateStr, 'finished') && isprop(toDisp, 'Read')
        if toDisp.Read
            trail = '(read)';
        else
            trail = '(unread)';
        end
        stateStr = [stateStr, ' ', trail];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayValue = iGetErrorVectorDisplayValue(anError)
    if isempty(anError) || ...
            (iscell(anError) && all(cellfun(@isempty, anError)))
        displayValue = '';
    else
        displayValue = 'Error';
    end
end
