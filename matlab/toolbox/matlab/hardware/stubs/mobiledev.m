function mdev = mobiledev(varargin)
%MOBILEDEV Read sensor data from mobile device running MATLAB Mobile.
%
%   Supported OS:
%   Android, Apple iOS
%
%   M = MOBILEDEV creates a mobiledev object m that reads sensor data from 
%   any device running MATLAB Mobile with the same MathWorks Account. 
%   The object can read data from five types of sensors: acceleration, 
%   angular velocity, orientation, magnetic field, and position. 
%   Use this syntax when you have only one device set up for sensing. 
%   
%   M = MOBILEDEV(devname) creates a mobiledev object to read data from the 
%   device identified by devname. Use this syntax when you have more than 
%   one device connected to your MathWorks account. You can create several 
%   mobiledev objects, each one for a different device. 
%   For a list of possible devices, use the mobiledevlist command.
%   
%   mobiledev methods:
%
%       Accessing logged data.
%           accellog - returns logged acceleration data
%           angvellog - returns logged angular velocity data
%           magfieldlog - returns logged magnetic field data
%           orientlog - returns logged orientation data       
%           poslog - returns logged position data
%
%       Discarding logged data.
%           discardlogs - discard all logged data
%
%   mobiledev properties:
%       Connected - Shows status of connection between MATLAB Mobile and mobiledev object in MATLAB
%       Logging - Shows and controls status of data transfer from device to MATLAB
%       InitialTimestamp - Time when first data point was transferred from 
%                          device to mobiledev in date format dd-mmm-yyyy HH:MM:SS.FFF.
%
%       Acceleration - Current acceleration reading: X, Y, Z in m/s^2
%       AngularVelocity - Current angular velocity reading: X, Y, Z in radians per second
%       Orientation - Current orientation reading: Azimuth, Pitch and Roll in degrees
%       MagneticField - Current magnetic field reading:  X, Y, Z in microtesla
%
%       Latitude - Current latitude reading in degrees
%       Longitude - Current longitude reading in degrees
%       Speed - Current speed reading in meters per second
%       Course - Current course reading in degrees relative to true north
%       Altitude - Current altitude reading in meters
%       HorizontalAccuracy - Current horizontal accuracy reading in meters
%
%       AccelerationSensorEnabled - Turns on/off accelerometer
%       AngularVelocitySensorEnabled - Turns on/off gyroscope
%       MagneticSensorEnabled - Turns on/off magnetometer
%       OrientationSensorEnabled - Turns on/off orientation sensor
%       PositionSensorEnabled - Turns on/off position sensor
%       SampleRate - Sets sample rate at which device will acquire the data
%       AvailableCameras - All cameras available on the device
%       AvailableMicrophones - All microphones available on the device
%       SelectedMicrophone - Specify name of microphone to access on the device
%       Microphone - Object representing selected microphone
%
%   Usage
%
%   Before using this function, make sure that your MATLAB is signed in to your
%   MathWorks account.
%
%   1. Start MATLAB Mobile.
%   2. If prompted, sign in to your MathWorks account.
%   3. In MATLAB, enter:  m = mobiledev to create a mobiledev object.
%      or
%      m = mobiledev(devname), where devname is the name of the device you are
%      creating a mobiledev object for. You can get a list of the avialable
%      devices using the mobiledevlist command.
%
%   Access Data
%
%   You can get the latest value of a specific measurement by
%   querying the corresponding property. For example:
%
%       m.Acceleration
%
%   You can use mobiledev methods to access the logged measurement values.
%   For example, to get logged acceleration values:
%
%       [a, t] = accellog(m)
%
%   See also MOBILEDEVLIST 

% Copyright 2014-2022 The MathWorks, Inc.
mdev = [];

% Check if the support package is installed.
try
    fullpathToUtility = which('mobilesensor.internal.MobileDevController');
    if isempty(fullpathToUtility) 
        % Support package not installed - Error.
        error(getString(message('MATLAB:hwstubs:general:spkgListNotInstalled', 'MATLAB Android Sensors or MATLAB iOS Sensors', '{''ML_ANDROID_SENSORS'', ''ML_APPLE_IOS_SENSORS''}')));
    else
        mdev = mobilesensor.internal.mobiledev(varargin{:});
    end
catch e
    throwAsCaller(e);
end
