classdef (Hidden) insSensor < fusion.internal.INSSENSORBaseMATLAB
%   This class is for internal use only. It may be removed in the future. 

%INSSENSOR  Simulink version of the insSensor. 
%   The INSSENSOR class emulates an ins/gps sensor 
%   System for use in the MATLAB System Block.
    
%   Copyright 2019-2021 The MathWorks, Inc.        

    %#codegen
   
    properties (Dependent, Nontunable)
        % SeedDouble - Random number seed as a double
        SeedDouble 
    end
    properties (Nontunable)
        % UseAccelAndAngVel - Turn on Angular Velocity and Acceleration
        UseAccelAndAngVel (1,1) logical = false
    end
    
    methods
        function obj = insSensor(varargin)
            setProperties(obj, nargin, varargin{:});
            obj.RandomStream = 'mt19937ar with seed';
        end
        
        function set.SeedDouble(obj, x)
            obj.Seed = x;
        end
        function x = get.SeedDouble(obj)
            x = double(obj.Seed);
        end
    end
    
    methods (Access = protected)
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@fusion.internal.INSSENSORBaseMATLAB(obj);
            s.UseAccelAndAngVel = obj.UseAccelAndAngVel;
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties.
            loadObjectImpl@fusion.internal.INSSENSORBaseMATLAB(obj, s, wasLocked);
            if isfield(s, 'UseAccelAndAngVel') % in case from an old release
                obj.UseAccelAndAngVel = s.UseAccelAndAngVel;
            end
        end

        function n = getNumOutputsImpl(obj)
            n = 3;
            if obj.UseAccelAndAngVel
                n = n + 2;
            end
        end
        function n = getNumInputsImpl(obj)
            n = 3;
            if obj.UseAccelAndAngVel
                n = n + 2;
            end
            if obj.TimeInput
                n = n + 1;
            end
        end
        function n = getOutputNamesImpl(obj)
            n = ["Position", "Velocity", "Orientation"];
            if obj.UseAccelAndAngVel
                n = [n,  "Acceleration", "AngularVelocity"];
            end
        end
        
        function n = getInputNamesImpl(obj)
            n = ["Position", ...
                "Velocity", ...
                "Orientation"];
            if obj.UseAccelAndAngVel
                n = [n , "Acceleration", "AngularVelocity"];
            end
            if obj.TimeInput
                n = [n , "HasGNSSFix"];
            end
        end
        
        function icon = getIconImpl(~)
            %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'sensorsim', 'ins', 'simulink', 'blockicons', 'INS.dvg');
            icon = matlab.system.display.Icon(filepath);
        end
        
        function validateInputsImpl(obj, position, velocity, orientation, varargin)
            % Validate position input and use it to determine numSamples
            % (frame size) and expectedDataType.
      
            validateattributes(position, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3});
            expectedDataType = class(position);
            numSamples = size(position, 1);

            % Validate velocity
            validateattributes(velocity, {expectedDataType}, ...
                {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3});
           
           % Validate orientation - quaternions, rotation matrices, or
           % Euler angles in degrees. 
            opass = true;    
            switch ndims(orientation)
                case 2
                    sz = size(orientation);
                    if sz(2) == 4 % a quaternion
                        valsize = true;
                        validateattributes(orientation, {expectedDataType}, ...
                            {'real', 'finite', '2d', 'size', [numSamples 4]});

                    elseif isequal(sz, [3 3]) && numSamples == 1
                        % A single rotation matrix
                        valsize = true;
                        validateattributes(orientation, {expectedDataType}, ...
                            {'real', 'finite', '2d', 'size', [3 3] } );
                    elseif isequal(sz, [numSamples 3])
                        % Euler angles
                        valsize = true;
                        validateattributes(orientation, {expectedDataType}, ...
                            {'real', 'finite', '2d', 'size', [numSamples 3] } );
                    else
                        valsize = false;
                    end
                    coder.internal.assert(valsize, ...
                        'shared_sensorsim_common:SimulinkCommon:ExpectedOrientation');
                case 3
                    validateattributes(orientation, {expectedDataType}, ...
                        {'real', 'finite', '3d', 'size', [3 3 numSamples]});
                otherwise
                    opass = false;
            end
            coder.internal.assert(opass, ...
                'shared_sensorsim_common:SimulinkCommon:ExpectedOrientation');

            % Validate additional inputs as necessary
            if obj.UseAccelAndAngVel
                % Acceleration
                validateattributes(varargin{1}, {expectedDataType}, ...
                    {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3});
                % Angular Velocity
                validateattributes(varargin{2}, {expectedDataType}, ...
                    {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3});
            end
            if obj.TimeInput
                validateattributes(varargin{end}, {'logical'}, ...
                    {'nrows', numSamples, 'ncols', 1});
            end
        end    

           
        function setupImpl(obj,  pos,vel, orient, varargin)
            if obj.TimeInput
                % pack into an array of structs, but leave off the last argument: gnss fix
                s = packInputToArrayOfStructs(pos, vel, orient, varargin{1:end-1});
                % Setup on one slice of the array of structs
                setupImpl@fusion.internal.INSSENSORBaseMATLAB(obj, s(1));
            else
                s = packInputToStructOfArrays(pos,vel,orient,varargin{:});
                % Setup on the full struct
                setupImpl@fusion.internal.INSSENSORBaseMATLAB(obj, s);
            end
        end
        
        function timevec = getSampleTimeForFrame(obj, frameLength)
            % Create a vector of timestamps for the current frame
            % The object is called every getSampleTimeWrapped. First
            % time in frame is getCurrentTimeWrapped.
            tFrameStart = getCurrentTimeWrapped(obj);
            stSpec = getSampleTimeWrapped(obj);
            sampleTime = stSpec.SampleTime;
            rate = sampleTime./frameLength;
            tFrameEnd = tFrameStart + sampleTime - rate;
            timevec = linspace(tFrameStart, tFrameEnd, frameLength);
        end
       function [po,vo,oo, varargout] = stepImpl(obj, pos,vel, orient, varargin)
            % Iterate over the inputs because Simulink can offer a frame of
            % HasGNSSFix.             
            
            % The base class takes a struct of arrays.  For ~TimeInput we
            % can just hand the base class all the data.  For TimeInput we
            % have to call the base class in a for-loop, sample-by-sample,
            % creating a struct as we go.
            
            if obj.TimeInput
                N = size(pos,1);
                timevec = getSampleTimeForFrame(obj, N); % Get timestamps for this frame
                % pack into an array of structs, but leave off the last argument: gnss fix
                s = packInputToArrayOfStructs(pos, vel, orient, varargin{1:end-1});
                so = s; % preallocate by copying
                for ii=1:N
                    % Propagate the GNSSFix input to the property:
                    obj.pHasGNSSFix = varargin{end}(ii);
                    st = stepImpl@fusion.internal.INSSENSORBaseMATLAB(obj, s(ii), timevec(ii));
                    so(ii) = st;
                end
                [po,vo,oo, varargout{1:nargout-3}] = unpackArrayOfStructsToOutput(so);
            else
                % Pack all the data into a scalar struct containing arrays
                % of data.
                s = packInputToStructOfArrays(pos,vel,orient,varargin{:});
                so = stepImpl@fusion.internal.INSSENSORBaseMATLAB(obj, s);
                po = so.Position;
                vo = so.Velocity;
                if isa(so.Orientation, 'quaternion')
                    oo = compact(so.Orientation);
                else
                    oo = so.Orientation;
                end
                if nargout > 3
                    varargout = {so.Acceleration, so.AngularVelocity};
                else
                    varargout = {};
                end
            end
       
        end
           
        % Propagators
        function [s1, s2, s3, varargout] = getOutputSizeImpl(obj)
            s1 = propagatedInputSize(obj, 1);
            s2 = propagatedInputSize(obj, 2);
            s3 = propagatedInputSize(obj, 3);
            switch nargout
                case 3
                    varargout ={};
                case 4
                    varargout = {s1};
                otherwise
                    varargout = {s1, s1};
            end
        end    
        
        function [dt1, dt2, dt3, varargout] = getOutputDataTypeImpl(obj)
           dt1 = propagatedInputDataType(obj,1);
           dt2 = dt1;
           dt3 = dt1;
           switch nargout
               case 3
                   varargout ={};
               case 4
                   varargout = {dt1};
               otherwise
                   varargout = {dt1, dt1};
           end
        end
        function [tf1, tf2, tf3, varargout]  = isOutputComplexImpl(~)
            tf1 = false;
            tf2 = false;
            tf3 = false;
            switch nargout
                case 3
                    varargout ={};
                case 4
                    varargout = {false};
                otherwise
                    varargout = {false, false};
            end
        end
        
        function [tf1, tf2, tf3, varargout] = isOutputFixedSizeImpl(~)
            tf1 = true;
            tf2 = true;
            tf3 = true;
            switch nargout
                case 3
                    varargout ={};
                case 4
                    varargout = {true};
                otherwise
                    varargout = {true, true};
            end
        end
        function flag = isInactivePropertyImpl(obj, prop)
            flag = isInactivePropertyImpl@fusion.internal.INSSENSORBaseMATLAB(obj, prop);
            % Now change the stuff for Accel and Ang Vel inputs
            switch prop
                case 'AccelerationAccuracy'
                    flag = ~obj.UseAccelAndAngVel;
                case 'AngularVelocityAccuracy'
                    flag = ~obj.UseAccelAndAngVel;
            end
        end     
        function s = getCurrentTimeWrapped(obj)
            % Wrapper around getCurrentTime. This is separated out into a
            % method so it can be overridden in the test harness.
            s = getCurrentTime(obj);
        end
        function  stSpec = getSampleTimeWrapped(obj)
            % Wrapper around getSampleTime. This is separated out into a
            % method so it can be overridden in the test harness.
            stSpec = getSampleTime(obj);
        end
    end
    
    methods (Access = protected, Static, Hidden)
        function groups = getPropertyGroupsImpl
            % Parameters - Noise Accuracies
            rollAcc = makeProp('RollAccuracy');
            pitchAcc= makeProp('PitchAccuracy');
            yawAcc = makeProp('YawAccuracy');
            posAcc = makeProp('PositionAccuracy');
            velAcc = makeProp('VelocityAccuracy');
            mountLoc = makeProp('MountingLocation');
            main = matlab.system.display.Section(...
                'Title', lookupDesc('Parameters'), ...
                'PropertyList', {mountLoc, rollAcc, pitchAcc, yawAcc, posAcc, velAcc});
            
            % Additional Kinematic Inputs
            inp =  matlab.system.display.internal.Property(...
                'UseAccelAndAngVel', 'Description', lookupDesc('AccelAngVel'));
            accAcc = makeProp('AccelerationAccuracy');
            avAcc = makeProp('AngularVelocityAccuracy');

            kin = matlab.system.display.Section(...
                'Title', lookupDesc('AdditionalKinematics'), ...
                'PropertyList', {inp, accAcc, avAcc});

            % GNSS Lock 
            timegnss =  matlab.system.display.internal.Property(...
                'TimeInput', 'Description', lookupDesc('TrackGNSSFix'));
            posErr = matlab.system.display.internal.Property('PositionErrorFactor', ...
                'Description', lookupDesc('PositionErrorFactor'));
            gnssInput = matlab.system.display.Section(...
                'Title', lookupDesc('GNSSFix'), ...
                'PropertyList', {timegnss, posErr});
               
            % Randomization
            sd = matlab.system.display.internal.Property(...
                'SeedDouble', 'Description', lookupDesc('Seed'), ...
                'UseClassDefault', false, 'Default', '67' );
            
            rnd = matlab.system.display.Section(...
                'Title', lookupDesc('Randomization'), ...
                'PropertyList', {sd}, ...
                'DependOnPrivatePropertyList', {'SeedDouble'});
            
            groups = [main, kin, gnssInput, rnd];
        end

        function header = getHeaderImpl
            blockTitle = string(lookupDesc('MaskTitle'));
            h1 = string(lookupDesc('MaskDescH1'));
            main = string(lookupDesc('MaskDescMain'));
            howto = string(lookupDesc('MaskDescHowTo'));
            io = string(lookupDesc('MaskDescIO'));
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', blockTitle, ...
                'ShowSourceLink', false, ...
                'Text', ...
                 h1 + newline + newline +  ....
                 main + newline + newline + ...
                 howto + newline + newline + ...
                 io);
        end
        
    end

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = true;
        end
    end
    
end
    
function p = makeProp(prop)
% Add a new property
    propunits = insSensor.(prop + "Units");
    p = matlab.system.display.internal.Property(prop, 'Description', [lookupDesc(prop) ' (' propunits ')']);
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_sensorsim_ins:insSensor:" + desc);
    txt = m.getString;
end

function s= packInputToStructOfArrays( pos,vel, orient, acc, av)
% Used in untimed mode (no HasGNSSFix port). We can make a single struct with
% each field containing a frame of data: a struct of arrays.

    if size(orient,2) == 4
        % N-by-4 quaternion
        oin = quaternion(orient);
    else
        % Euler angles or rotation matrix
        oin = orient;
    end
    % Note: code generation requires the struct order to be Orientation,
    % Position, Velocity, Acceleration, AngularVelocity because the struct
    % must match the one passed up from the base class.
    s = struct('Orientation', oin, 'Position', pos, 'Velocity', vel);
    % Add extra kinematics if present
    if nargin > 3
        s.Acceleration =  acc;
        s.AngularVelocity = av;
    end
end
function s= packInputToArrayOfStructs(pos,vel, orient, acc, av)
% Used when the block has a HasGNSSFix time port and the input data frames
% need to be iterated over sample-by-sample. We need an array of structs.
N = size(pos,1);

extraKinematics = nargin > 3;

% Note: code generation requires the struct order to be Orientation,
% Position, Velocity, Acceleration, AngularVelocity because the struct
% must match the one passed up from the base class.
 
% preallocate a slice of the output array-of-structs
if size(orient,2) == 4
    % N-by-4 "quaternion" matrix, convert to a N-by-1 quaternion
    oin = quaternion(orient);
    ex.Orientation = oin(1,:);
    isRotmat = false;
elseif (ndims(orient) == 3) || isequal(size(orient), [3 3])
    % Rotation matrix
    oin = orient;
    ex.Orientation = oin(:,:,1);
    isRotmat = true;
else
    % Euler angles
    oin = orient;
    ex.Orientation = oin(1,:);
    isRotmat = false;
end

ex.Position = zeros(1,3, 'like', pos);
ex.Velocity = zeros(1,3, 'like', vel);

if extraKinematics
    ex.Acceleration = zeros(1,3, 'like', acc);
    ex.AngularVelocity = zeros(1,3, 'like', av);
end

% Preallocate the full array-of-structs
s = repmat(ex,N,1); 

for ii=1:N
    if isRotmat
        s(ii).Orientation = oin(:,:,ii);
    else
        s(ii).Orientation =  oin(ii,:);
    end
    s(ii).Position = pos(ii,:);
    s(ii).Velocity = vel(ii,:);
    if extraKinematics
        s(ii).Acceleration =  acc(ii,:);
        s(ii).AngularVelocity = av(ii,:);
    end
end
end

function [po,vo,oo, varargout] = unpackArrayOfStructsToOutput(so)
N = numel(so);
po = vertcat(so.Position);
vo = vertcat(so.Velocity);
oEx = so(1).Orientation;
if isa(oEx, 'quaternion')
    % 1-by-1-by-N array of quaternion objects
    oo = zeros(N,4, classUnderlying(so(1).Orientation));
    oo(:) = compact(vertcat(so.Orientation)); % Will make N-by-4
elseif size(oEx,1) == 1
    % 1-by-1-by-N array of Euler angles
    oo = vertcat(so.Orientation); % Will make N-by-3
else
    % 3-by-3-by-N Rotation matrices
    oo = cat(3,so.Orientation); 
end
if nargout > 3
    varargout = {vertcat(so.Acceleration), vertcat(so.AngularVelocity)};
else
    varargout = {};
end
end
