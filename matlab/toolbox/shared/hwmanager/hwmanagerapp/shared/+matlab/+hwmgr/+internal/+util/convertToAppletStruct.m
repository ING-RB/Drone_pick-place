function appletStruct = convertToAppletStruct(appletClass, varargin)
    % CONVERTTOAPPLETSTRUCT - This is a utility function which converts an
    % applet name to a applet struct with fields AppletName and Constructor
    
    % Copyright 2018 The MathWorks, Inc.
      
    % validate input arguments
    if isstruct(appletClass)
        % when appletClass is an applet struct, varargin should be empty
        validateattributes(appletClass, {'struct'}, {'scalar'}, 'matlab.hwmgr.internal.util.convertToAppletStruct', 'appletClass');
        validateattributes(appletClass.AppletName, {'char', 'string'}, {'nonempty', 'scalartext'}, 'matlab.hwmgr.internal.util.convertToAppletStruct', 'appletClass.AppletName');
        validateattributes(appletClass.Constructor, {'function_handle'}, {'nonempty'}, 'matlab.hwmgr.internal.util.convertToAppletStruct', 'appletClass.Constructor');
        validateattributes(varargin, {'cell'}, {'size', [0, 0]}, 'matlab.hwmgr.internal.util.convertToAppletStruct', 'varargin')
    else
        validateattributes(appletClass, {'char', 'string'}, {'nonempty', 'scalartext'}, 'matlab.hwmgr.internal.launchApplet', 'appletClass');
    end

    if ~isempty(varargin)
        % get optional device input and validate
        device = varargin{1};
        validateattributes(device, {'matlab.hwmgr.internal.Device'}, {}, 'matlab.hwmgr.internal.util.convertToAppletStruct', '2nd input');
    end

    appletStruct = struct('AppletName', {}, 'Constructor', {});
    if ~isstruct(appletClass)
        if exist(appletClass, 'class') == 8
            if isempty(varargin)
                % When this method is invoked in launchApplet, no device is 
                % provided as input. In this case, we provide the simple 
                % constructor which is the class name.
                appletStruct = struct('AppletName', appletClass, 'Constructor', str2func(appletClass));                
            else              
                % Create the applet object using default constructor
                appObj = feval(appletClass);
                % Get possible non-default constructors
                constructorOptions = appObj.getConstructorOptions(device);
                % Create struct array of current applet name and constructor pairs
                dupNames = repmat({appletClass}, size(constructorOptions));
                appletStruct = struct('AppletName', dupNames, 'Constructor', constructorOptions);
            end
        else
            % warning to downstream team of invalid applet class.
            warnID = "hwmanagerapp:hwmgrshared:InvalidAppletClass";
            warning(warnID, message(warnID, appletClass).string);
        end
    else
        appletStruct = appletClass;
    end
end