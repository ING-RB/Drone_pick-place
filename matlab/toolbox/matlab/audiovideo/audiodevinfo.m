function devInfo = audiodevinfo(varargin)
%

%   AUDIODEVINFO Audio device information.
%   DEVINFO = AUDIODEVINFO returns a structure DEVINFO containing two fields,
%   input and output.  Each of these fields is an array of structures, each
%   structure containing information about one of the audio input or output
%   devices on the system.  The individual device structure fields are Name
%   (name of the device, string), DriverVersion (version of the installed
%   device driver, string), and ID (the device's ID).
%
%   AUDIODEVINFO(IO) returns the number of input or output audio devices on
%   the system.  Set IO = 1 for input, IO = 0 for output.
%
%   AUDIODEVINFO(IO, ID) returns the name of the input or output audio device
%   with the given device ID.
%
%   AUDIODEVINFO(IO, NAME) returns the device ID of the input or output audio
%   device with the given name (partial matching, case sensitive).  If no
%   audio device is found with the given name, an error is generated.
%
%   AUDIODEVINFO(IO, ID, 'DriverVersion') returns the driver version string of
%   the specified audio input or output device.
%
%   AUDIODEVINFO(IO, RATE, BITS, CHANS) returns the device ID of the first
%   input or output device that supports the sample rate, number of bits,
%   and number of channels specified in RATE, BITS, and CHANS, respectively.
%   If no supportive device is found, -1 is returned.
%
%   AUDIODEVINFO(IO, ID, RATE, BITS, CHANS) returns logical 1 (true) if the
%   input or output audio device specified by ID supports the sample rate,
%   number of bits per sample, and number of channels specified by the
%   values of Fs, nBits, and nChannels, respectively, and logical 0 (false)
%   otherwise
%
%
%   See also AUDIOPLAYER, AUDIORECORDER, AUDIODEVRESET.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;
if Capability.isSupported(Capability.LocalClient)
    devInfo = audiovideo.internal.audiodevinfoDesktop(varargin{:});
else
    % This is running in MATLAB Online
    devInfo = audiovideo.internal.audiodevinfoOnline(varargin{:});
end
