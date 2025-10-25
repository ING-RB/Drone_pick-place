classdef BuildContentOperatorList < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Plugins (1,:) cell
    end
    
    properties (Access = private)
        Operators (1,1) struct
    end
    
    methods
        function list = BuildContentOperatorList(baseOperator)
            arguments
                baseOperator (1,1) matlab.buildtool.internal.BuildContentOperator
            end
            
            import matlab.buildtool.internal.allPluginMethodNames;
            
            allMethods = allPluginMethodNames();
            list.Operators = cell2struct(repmat({{baseOperator}}, 1, numel(allMethods)), allMethods, 2);
        end
        
        function addPlugin(list, plugin)
            arguments
                list (1,1) matlab.buildtool.internal.BuildContentOperatorList
                plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
            end
            
            import matlab.buildtool.internal.getPluginMethodsOverriddenBy;
            
            list.Plugins{end+1} = plugin;
            
            pluginMethodNames = getPluginMethodsOverriddenBy(plugin);
            for i = 1:numel(pluginMethodNames)
                list.Operators.(pluginMethodNames(i)){end+1} = plugin;
            end
        end
        
        function iter = getIteratorFor(list, methodName)
            arguments
                list (1,1) matlab.buildtool.internal.BuildContentOperatorList
                methodName (1,1) string
            end
            
            import matlab.buildtool.internal.BuildContentOperatorReverseIterator;
            iter = BuildContentOperatorReverseIterator(list.Operators.(methodName));
        end
    end
end

