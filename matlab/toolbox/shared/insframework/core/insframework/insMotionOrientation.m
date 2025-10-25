classdef insMotionOrientation < positioning.INSMotionModel
%INSMOTIONORIENTATION Motion model for 3D orientation estimation 
%   M = INSMOTIONORIENTATION creates an object which models
%   orientation-only motion with constant angular velocity.  Pass M to the
%   insEKF function to enable estimation of 3D orientation. Using M will
%   cause the insEKF to track the following quantities in the State vector:
%
%   Quantity                                    Frame
%   -------------------------------------------------------
%   Orientation quaternion              Navigation to Body
%   Angular Velocity                            Body
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   filtPose = insEKF(acc, gyro, mag, insMotionOrientation);
%
%   See also: insEKF, insOptions, insAccelerometer

%   Copyright 2021 The MathWorks, Inc.      


%#codegen


    %%%% Optional Methods %%%%
    methods 
        function s = modelstates(~, opts) 
            % MODELSTATES Define the tracked states for orientation-only estimation.
            %   MODELSTATES returns a scalar struct which describes the
            %   states needed for 3D orientation-only estimation using a
            %   constant angular velocity motion model. Orientation is
            %   tracked as a quaternion which describes the frame rotation
            %   that takes quantities in the global frame to quantities in
            %   body frame. 
            %
            %  See also: insEKF, insEKF/stateparts
            
            s = struct('Orientation', [ones(1,opts.Datatype) zeros(1,3, opts.Datatype)], ...
                'AngularVelocity', zeros(1,3, opts.Datatype));
        end
    end
    
    methods
        function statesdot = stateTransition(~, filt, dt, varargin)
            %STATETRANSITION State transition function for orientation estimation 
            %  STATETRANSITION returns a struct with fields
            %  Orientation and AngularVelocity, describing the state
            %  transition function of a constant angular velocity motion
            %  model. 
            %
            %   See also: insMotionOrientation/modelstates
            
            av = stateparts(filt, 'AngularVelocity');
            q = stateparts(filt, 'Orientation');
            angvelBodyX = av(1);
            angvelBodyY = av(2);
            angvelBodyZ = av(3);
            q0 = q(1);
            q1 = q(2);
            q2 = q(3);
            q3 = q(4);
            
            f = zeros(1,7, 'like', filt.State);
            f(1) = - (angvelBodyX*q1)/2 - (angvelBodyY*q2)/2 - (angvelBodyZ*q3)/2;
            f(2) = (angvelBodyX*q0)/2 - (angvelBodyY*q3)/2 + (angvelBodyZ*q2)/2;
            f(3) = (angvelBodyY*q0)/2 + (angvelBodyX*q3)/2 - (angvelBodyZ*q1)/2;
            f(4) = (angvelBodyY*q1)/2 - (angvelBodyX*q2)/2 + (angvelBodyZ*q0)/2;
            f(5) = 0;
            f(6) = 0;
            f(7) = 0;
            
            statesdot = struct('Orientation', f(1:4), 'AngularVelocity', f(5:7));
            
        end
        
        function dfdx = stateTransitionJacobian(~, filt, dt, varargin)
            %STATETRANSITIONJACOBIAN Jacobian of sensor stateTransition function
            %  STATETRANSITIONJACOBIAN returns a struct with identical
            %  fields as sensorStates, describing the Jacobian of the
            %  per-state transition function relative to the State property
            %  of filter FILT. Each field value of STATESDOT should be a
            %  M-by-numel(FILT.State) row vector of partial derivatives of
            %  that field's state transition function relative to the state
            %  vector. Here M is the number of elements in a measurement
            %  from this sensor.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, a numerical Jacobian will be used instead.
            %
            %  See also: insEKF
            
            state = filt.State;
            oidx = stateinfo(filt, 'Orientation');
            avidx = stateinfo(filt, 'AngularVelocity');
            
            angvelBodyX = state(avidx(1));
            angvelBodyY = state(avidx(2));
            angvelBodyZ = state(avidx(3));
            q0 = state(oidx(1));
            q1 = state(oidx(2));
            q2 = state(oidx(3));
            q3 = state(oidx(4));
            
            N = numel(state);
            dOrientdx = zeros(4, N, 'like', state);
            
            dOrientdx(1,oidx) = [0, -angvelBodyX/2, -angvelBodyY/2, -angvelBodyZ/2];
            dOrientdx(1,avidx) = [-q1/2, -q2/2, -q3/2];
            
            dOrientdx(2,oidx) = [angvelBodyX/2, 0, angvelBodyZ/2, -angvelBodyY/2];
            dOrientdx(2,avidx) = [q0/2, -q3/2, q2/2];
            
            dOrientdx(3,oidx) = [angvelBodyY/2, -angvelBodyZ/2, 0, angvelBodyX/2];
            dOrientdx(3,avidx) = [q3/2, q0/2, -q1/2];
            
            dOrientdx(4,oidx) = [angvelBodyZ/2, angvelBodyY/2, -angvelBodyX/2, 0];
            dOrientdx(4,avidx) = [-q2/2, q1/2, q0/2];
            
            dAVdx = zeros(3, N, 'like',state);
            
            dfdx = struct('Orientation', dOrientdx, 'AngularVelocity', dAVdx);

        end
    end

   
end



