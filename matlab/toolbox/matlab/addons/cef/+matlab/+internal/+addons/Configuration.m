
classdef(Sealed = true, Hidden = true) Configuration < handle
  % Configuration - This class define and set the following configuration parameters for 
  % add-ons infrastructure based on MATLAB Platform
  %     1. isClientRemote: This parameter is set to true if MATLAB is
  %     launched in worker mode and is serving as a backend for MATLAB on
  %     the web
  %     2. viewer: This is sent as a query parameter to Add-on Explorer.
  %     Explorer filter's the list of Add-ons based on this parameter.
  %     Allowed values - {"ml_desktop", "ml_online"}
  
  %   Copyright: 2019-2021 The MathWorks, Inc.
    
    methods (Static, Access = public)
       
        function val = isClientRemote()
            if (isLocalClient)
                val = false;
            else
                val = true;
            end
        end
        
        function val = viewer()            
            val = "ml_desktop";
            if (~isLocalClient)
                val = "ml_online";
            end
        end
        
        function configureForMatlabOnline()
            % ENABLE GET ADD-ONS TOOLSTRIP. REF: g2215040
            sendMessageToMatlabOnline("enableGetAddOns");
        end
    end
end