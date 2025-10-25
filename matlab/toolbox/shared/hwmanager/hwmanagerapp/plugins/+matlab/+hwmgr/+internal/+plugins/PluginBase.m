classdef PluginBase < handle & matlab.mixin.Heterogeneous
   % This is the base interface class for a Hardware Manager plugin. This
   % class should be subclassed in order to implement a hardware manager
   % plugin.
   
   % Copyright 2017 Mathworks
   
   methods(Abstract, Access = public)
        % Returns a Device Provider
        deviceProvider = getDeviceProvider(obj)
        
        % Returns an Applet Provider
        appletProvider = getAppletProvider(obj)
   end
    
   
end