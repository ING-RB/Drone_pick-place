function varargout = UseHardwareAcceleration(action)
%USEHARDWAREACCELERATION Control Hardware Acceleration Mode when reading
%videos
%   STATUS = USEHARDWAREACCELERATION Query the current state of the usage
%   of hardware acceleration for reading videos. STATUS is a character
%   vector that returns 'on' if hardware acceleration is enabled and 'off'
%   if disabled.
%
%   USEHARDWAREACCELERATION(ACTION) sets the hardware acceleration mode to
%   ACTION. ACTION is a character vector that can take the following
%   values:
%       'on'        - Enable hardware acceleration
%       'off'       - Disable hardware acceleration
%       'default'   - Use default hardware acceleration mode
%

%   Authors: DI
%   Copyright 2016 The MathWorks, Inc.
    s = settings;
    
    % This function returns either zero or one output argument.
    nargoutchk(0, 1);
        
    if nargin == 0
        if s.matlab.videoreader.UseHardwareAcceleration.ActiveValue
            varargout{1} = 'on';
        else
            varargout{1} = 'off';
        end
        return;
    end
    
    % If the function is being called to modify the Hardware Acceleration
    % Mode, then no output is provided.
    if nargin == 1 && nargout ~= 0
        msgObj = message('multimedia:video:invalidNumOutputArgsDuringSet');
        throwAsCaller( MException(msgObj.Identifier, getString(msgObj)) );
    end

    validateattributes(action , {'char'}, {'row'});

    switch lower(action)
        case 'on'
            s.matlab.videoreader.UseHardwareAcceleration.PersonalValue = true;
        case 'off'
            s.matlab.videoreader.UseHardwareAcceleration.PersonalValue = false;
        case 'default'
            s.matlab.videoreader.UseHardwareAcceleration.PersonalValue = ...
                s.matlab.videoreader.UseHardwareAcceleration.FactoryValue;
        otherwise
            msgObj = message('multimedia:video:invalidHwAccelMode');
            throwAsCaller( MException(msgObj.Identifier, getString(msgObj)) );
    end
end