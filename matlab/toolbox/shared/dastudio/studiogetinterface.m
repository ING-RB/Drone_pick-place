function schemas = studiogetinterface( whichMenu, callbackInfo )
%

% Copyright 2009 The MathWorks, Inc.
    schemas = {};
    
    if ~isempty( callbackInfo.studio.App )
        interface = callbackInfo.studio.App.getMenuInterface();
    else
        interface.interfaceFile = 'studioGetDefaultInterface';
        interface.gatewayFile = '';
    end
    
    try
        if isempty( interface.gatewayFile )
            schemas = feval( interface.interfaceFile, whichMenu, callbackInfo );
        else
            schemas = feval( interface.gatewayFile, interface.interfaceFile, ...
                             whichMenu, callbackInfo );
        end
    catch Err
        switch( whichMenu )
            case 'MenuBar'
                schemas = { { @DAStudio.ErrorMenu, Err } };
            otherwise
                rethrow(Err);
        end
        disp('MATLAB Exception: studiogetinterface()');
    end
end
