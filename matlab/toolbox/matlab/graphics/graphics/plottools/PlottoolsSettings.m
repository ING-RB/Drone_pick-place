classdef PlottoolsSettings < matlab.settings.internal.FactorySettingsDefinition
%
% Copyright the MathWorks, 2023

  methods(Static) 

    function createTree(plottools) 
      plottoolProps = plottools.addGroup('figuretoolstrip');       

      plottoolProps.addSetting('showcode', ... 
        'FactoryValue', false, ...  
        'ValidationFcn', @matlab.settings.mustBeLogicalScalar);
    end 

    function upgraders = createUpgraders()
      upgraders = matlab.settings.SettingsFileUpgrader("v0"); 
    end 
  end 
end 