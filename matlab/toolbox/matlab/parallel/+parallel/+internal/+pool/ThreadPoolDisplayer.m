% Displayer for threadpool objects

% Copyright 2021-2024 The MathWorks, Inc.

classdef ( Hidden ) ThreadPoolDisplayer < parallel.internal.display.AbstractDisplayer
    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
        DisplayItemFactory
    end

    methods
        function obj = ThreadPoolDisplayer(varargin)

            if nargin == 0
                classToDisplay = 'parallel.Pool';
            else
                classToDisplay = class(varargin{1});
            end

            obj@parallel.internal.display.AbstractDisplayer(...
                classToDisplay, classToDisplay);
            obj.DisplayHelper = parallel.internal.display.DisplayHelper(...
                numel('NumWorkers'));
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
            if ~toDisp.Connected
                disp(getString(message('MATLAB:parallel:pool:ShutdownPool')));
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
            dimStr = obj.DisplayHelper.formatDimensionTextOnly(size(toDisp), obj.formatDocLink(class(toDisp)));
            fprintf('%s\n', dimStr);
        end

        function displaySpecificItems(obj, toDisp)
            % Gets the specified properties from the toDisp object and
            % displays them.

            % Create an empty map to hold displayable pool properties
            poolPropertyMap = dictionary(string.empty(), parallel.internal.display.Default.empty());

            % Display order to put into propNames
            propNames = {'NumWorkers', 'Busy'};

            poolPropertyMap("NumWorkers") = obj.DisplayItemFactory.createDefaultItem(toDisp.NumWorkers);
            poolPropertyMap("Busy") = obj.DisplayItemFactory.createDefaultItem(toDisp.Busy);
            
            % Get the visible properties of this class to check if we
            % should display FileStore/ValueStore.
            visibleProps = properties(toDisp);

            if ismember("FileStore", visibleProps)
                propNames{end + 1} = 'FileStore';
                poolPropertyMap("FileStore") = obj.DisplayItemFactory.createDefaultItem(toDisp.FileStore);
            end

            if ismember("ValueStore", visibleProps)
                propNames{end + 1} = 'ValueStore';
                poolPropertyMap("ValueStore") = obj.DisplayItemFactory.createDefaultItem(toDisp.ValueStore);
            end

            numFutures = numel(toDisp.FevalQueue.QueuedFutures) + numel(toDisp.FevalQueue.RunningFutures);
            % Convention is not to display the FevalQueue property if no
            % futures are pending/running.
            if numFutures > 0
                if numFutures == 1
                    messageObj = message('MATLAB:parallel:future:FevalQueueOneRequest');
                else
                    messageObj = message('MATLAB:parallel:future:FevalQueueManyRequests', numFutures);
                end
                propNames{end + 1} = 'FevalQueue';
                poolPropertyMap("FevalQueue") = obj.DisplayItemFactory.createDefaultItem(messageObj.getString);
            end

            for ii = 1:numel(propNames)
                displayValue = poolPropertyMap(propNames{ii});
                displayValue.displayInMATLAB(propNames{ii});
            end
        end
    end
end
