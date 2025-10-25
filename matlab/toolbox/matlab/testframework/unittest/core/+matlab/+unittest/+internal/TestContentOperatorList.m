classdef TestContentOperatorList < handle
    %

    % Copyright 2017-2023 The MathWorks, Inc.

    properties (SetAccess=private)
        Plugins = {};
        HasQualifyingPlugin = false;
    end
    
    properties (Access=private)
        Operators;
    end

    properties (Access=private, WeakHandle)
        BaseOperator matlab.unittest.internal.TestContentOperator;
    end

    methods
        function list = TestContentOperatorList(baseOperator)
            import matlab.unittest.internal.allPluginMethodNames;
            
            allMethods = allPluginMethodNames;
            list.BaseOperator = baseOperator;
            for i = 1:numel(allMethods)
                list.Operators.(allMethods(i)) = matlab.unittest.internal.PluginList;
            end
        end
        
        function bool = hasPluginThatImplements(list, methodName)
            bool = numel(list.Operators.(methodName).ListOfPlugins) > 0;
        end
        
        function addPlugin(list, plugin)
            import matlab.unittest.internal.getPluginMethodsOverriddenBy;

            plugin.validateCompatibilityWithRunnerPluginList_(list.Plugins);
            
            list.Plugins{end+1} = plugin;
            
            list.HasQualifyingPlugin = list.HasQualifyingPlugin || ...
                isa(plugin, "matlab.unittest.plugins.QualifyingPlugin");
            
            pluginMethodNames = getPluginMethodsOverriddenBy(plugin);
            for i = 1:numel(pluginMethodNames)
                list.Operators.(pluginMethodNames(i)).ListOfPlugins{end+1} = plugin;
            end
        end
        
        function iter = getIteratorFor(list, methodName)
            import matlab.unittest.internal.TestContentOperatorReverseIterator;
            iter = TestContentOperatorReverseIterator(list.Operators.(methodName), list.BaseOperator);
        end
    end
end
