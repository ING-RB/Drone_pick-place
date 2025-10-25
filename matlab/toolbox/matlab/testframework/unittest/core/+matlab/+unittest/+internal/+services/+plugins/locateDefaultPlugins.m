function plugins = locateDefaultPlugins(interface, namespace, pluginProviderData)
% locateDefaultPlugins - Dynamically locate plugins.
%   By default, the testing framework will add these plugins to the factory
%   default list when running tests.
%
%   PLUGINS = locateDefaultPlugins(INTERFACE, NAMESPACE, PLUGINPROVIDERDATA) locates 
%   only those plugins provided by services deriving from the specified 
%   INTERFACE and residing under the specified NAMESPACE and determined
%   by the PLUGINPROVIDERDATA, which is an object of class 
%   matlab.unittest.internal.plugins.PluginProviderData
%
%
% See also: matlab.unittest.services.plugins.TestRunnerPluginService

% Copyright 2017-2023 The MathWorks, Inc.
import matlab.automation.internal.services.ServiceLocator
import matlab.unittest.internal.services.ServiceFactory
import matlab.unittest.internal.services.plugins.TestRunnerPluginLiaison

namespaceMetadata = meta.package.fromName(namespace);
serviceLocator = ServiceLocator.forNamespace(namespaceMetadata);

serviceClassesWithInterface = serviceLocator.locate(interface);
serviceFactory = ServiceFactory;
pluginServices = serviceFactory.create(serviceClassesWithInterface);

pluginLiaison = TestRunnerPluginLiaison();
pluginLiaison.PluginProviderData = pluginProviderData;
pluginServices.fulfill(pluginLiaison);
plugins = pluginLiaison.Plugins;
end

% LocalWords:  PLUGINPROVIDERDATA
