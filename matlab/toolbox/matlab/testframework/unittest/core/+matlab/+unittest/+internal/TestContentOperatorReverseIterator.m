classdef TestContentOperatorReverseIterator < handle
    %

    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties (Access=private)
        CurrentIndex;
    end
    
    properties (Dependent, SetAccess=private)
        HasNext;
    end

    properties (SetAccess=private, WeakHandle)
        LastOperator matlab.unittest.internal.TestContentOperator;
        PluginList matlab.unittest.internal.PluginList;
    end
    
    methods
        function iter = TestContentOperatorReverseIterator(pluginList, baseOperator)
            iter.PluginList = pluginList;
            iter.CurrentIndex = numel(pluginList.ListOfPlugins);
            iter.LastOperator = baseOperator;
        end
        
        function advance(iter)
            iter.CurrentIndex = iter.CurrentIndex - 1;
        end
        
        function bool = get.HasNext(iter)
            bool = iter.CurrentIndex > 0;
        end
        
        function operator = getCurrentOperator(iter)
            if iter.HasNext
                operator = iter.PluginList.ListOfPlugins{iter.CurrentIndex};
            else
                operator = iter.LastOperator;
            end
        end
        
    end
end
