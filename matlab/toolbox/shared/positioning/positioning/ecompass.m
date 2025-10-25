function O = ecompass(a, m, format, varargin)
% ECOMPASS - Orientation from accelerometer and magnetometer and readings
%   O = ECOMPASS(A, M) returns an orientation quaternion that rotates
%   quantities in the global frame of reference to the sensor frame of
%   reference. Specify the proper acceleration in the sensor's frame of
%   reference, A, and the magnetic field in the sensor's frame of
%   reference, M, as N-by-3 matrices. The output, O, is returned as an
%   N-by-1 quaternion.  
%   
%   O = ECOMPASS(..., FORMAT) specifies the orientation format for O.
%   FORMAT must be:
%       'quaternion'    - (default) a quaternion object
%       'rotmat'        - a rotation matrix    
%   
%   O = ECOMPASS(A, M, FORMAT, 'ReferenceFrame', FRAME) specifies the
%   reference frame for O. FRAME must be:
%       'NED'    - North-East-Down
%       'ENU'    - East-North-Up
%
%   If not specified, the orientation produced is with respect to the NED 
%   coordinate reference frame. 
%
%   Example:
%
%       m = [19.535 -5.109 47.930];     % Magnetic field strength (uT) 
%                                       % in Boston, MA 
%                                       % when pointed to True North
%
%       a = [0 0 9.8];    % Acceleration in (m/s^2) when device 
%                         % is on a flat surface.
%
%       q = ecompass(a,m)
%       e = eulerd(q, 'ZYX', 'frame');
%       declBos = -e(1)    % Declination for Boston    
%
%   See also QUATERNION, IMUFILTER, AHRSFILTER

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen


% Determine output format: quaternion or rotation matrix
opts = {'quaternion', 'rotmat'};
if nargin > 2
    fmt = validatestring(format, opts, 'ecompass', 'FORMAT', 3);
    makeQuat = strcmpi(fmt, 'quaternion');
else
    makeQuat = true;
end

% Determine reference frame.
frameOpts = fusion.internal.frames.ReferenceFrame.getOptions;
frameStructDefaults = struct('ReferenceFrame', ...
    fusion.internal.frames.ReferenceFrame.getDefault);
frameStruct = matlabshared.fusionutils.internal.setProperties( ...
    frameStructDefaults, numel(varargin), varargin{:});
navFrameStr = validatestring(frameStruct.ReferenceFrame, frameOpts, ...
    'ecompass', 'REFERENCEFRAME');
navFrame = fusion.internal.frames.ReferenceFrame.getMathObject(navFrameStr);

if isempty(m) && isempty(a)
    
    if isa(m, 'single') || isa(a, 'single')
        R = zeros(3,3,size(m,1), 'single');
    else
        R = zeros(3,3, size(m,1), 'double');
    end
    
else
    
    validateattributes(m, {'double', 'single'}, {'2d', 'ncols', 3, ...
       'nonempty', 'finite', 'nonsparse'}, 'ecompass', ...
       'MagneticField');

    validateattributes(a, {'double', 'single'}, {'2d', 'ncols', 3, ...
       'nonempty', 'finite', 'nonsparse' }, 'ecompass', ...
       'Acceleration');

    numframes = size(a,1);
    coder.internal.assert(isequal(numframes, size(m,1)), ...
       'shared_positioning:ecompass:NumSamplesMismatch', 'Acceleration', ...
       'MagneticField');

   R = navFrame.ecompass(a, m);
end

if makeQuat
    O = quaternion(R, 'rotmat', 'frame');
else
    O = R;
end

end
