classdef insMotionPose < positioning.INSMotionModel
%INSMOTIONPOSE Motion model for 3D orientation estimation 
%   M = INSMOTIONPOSE creates an object which models 3D pose with constant
%   acceleration and constant angular velocity.  Pass M to the insEKF
%   function to enable the estimation of 3D pose. Using M will cause the
%   insEKF to track the following quantities in the State vector:
%
%   Quantity                              Reference Frame
%   -------------------------------------------------------
%   Orientation quaternion              Navigation to Body
%   Angular Velocity                            Body
%   Position                                 Navigation
%   Velocity                                 Navigation
%   Acceleration                             Navigation
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   gps = insGPS
%   filtPose = insEKF(acc, gyro, mag, gps, insMotionPose);
%
%   See also: insEKF, insOptions, insMotionOrientation

%   Copyright 2021 The MathWorks, Inc.

%#codegen   

    methods 
        function s = modelstates(~, opts)
            % MODELSTATES Define the tracked states for pose estimation
            %   MODELSTATES returns a scalar struct which describes the
            %   states needed for 3D pose estimation using a constant
            %   acceleration and angular velocity motion model. Orientation
            %   is tracked as a quaternion which describes the frame
            %   rotation that takes quantities in the global frame to
            %   quantities in the body frame. 
            %
            %  See also: insEKF, insEKF/stateparts
               s = struct('Orientation', [ones(1,opts.Datatype) zeros(1,3, opts.Datatype)], ...
                'AngularVelocity', zeros(1,3, opts.Datatype), ...
                'Position', zeros(1,3, opts.Datatype), ...
                'Velocity', zeros(1,3, opts.Datatype), ...
                'Acceleration', zeros(1,3, opts.Datatype));
        end
    end
    methods 
        function statesdot = stateTransition(~, filt, ~, varargin)
            %STATETRANSITION State transition function for pose estimation 
            %  STATETRANSITION returns a struct with fields Orientation,
            %  AngularVelocity, Position, Velocity, and Acceleration,
            %  describing the state transition function of a constant
            %  acceleration and constant angular velocity motion model. 
            %
            %   See also: insMotionPose/modelstates
            
            idx = stateinfo(filt);
            state = filt.State;
            angvelBodyX = state(idx.AngularVelocity(1));
            angvelBodyY = state(idx.AngularVelocity(2));
            angvelBodyZ = state(idx.AngularVelocity(3));
            q0 = state(idx.Orientation(1));
            q1 = state(idx.Orientation(2));
            q2 = state(idx.Orientation(3));
            q3 = state(idx.Orientation(4));
            velNavX = state(idx.Velocity(1));
            velNavY = state(idx.Velocity(2));
            velNavZ = state(idx.Velocity(3));
            accNavX = state(idx.Acceleration(1));
            accNavY = state(idx.Acceleration(2));
            accNavZ = state(idx.Acceleration(3));
           
            % preallocate
            qdot = zeros(1,4, 'like', state);
            pdot = zeros(1,3, 'like', state); 
            vdot =  zeros(1,3, 'like', state);

            qdot(1) = - (angvelBodyX*q1)/2 - (angvelBodyY*q2)/2 - (angvelBodyZ*q3)/2;
            qdot(2) = (angvelBodyX*q0)/2 - (angvelBodyY*q3)/2 + (angvelBodyZ*q2)/2;
            qdot(3) = (angvelBodyY*q0)/2 + (angvelBodyX*q3)/2 - (angvelBodyZ*q1)/2;
            qdot(4) = (angvelBodyY*q1)/2 - (angvelBodyX*q2)/2 + (angvelBodyZ*q0)/2;
            avdot = zeros(1, 3, 'like', state);
            pdot(1) = velNavX;
            pdot(2) = velNavY;
            pdot(3) = velNavZ;
            vdot(1) = accNavX;
            vdot(2) = accNavY;
            vdot(3) = accNavZ;
            adot = zeros(1, 3, 'like', state);
            statesdot = struct('Orientation' ,qdot, ...
                'AngularVelocity', avdot, ...
                'Position', pdot, ...
                'Velocity', vdot, ...
                'Acceleration', adot);
        end
        
        function dfdx = stateTransitionJacobian(~, filt, ~, varargin)
            %STATETRANSITIONJACOBIAN Jacobian of sensor stateTransition function
            %  STATETRANSITIONJACOBIAN returns a struct with identical
            %  fields as modelstates, describing the Jacobian of the
            %  per-state transition function relative to the State property
            %  of filter FILT. Each field value of STATESDOT should be a
            %  M-by-numel(FILT.State) row vector of partial derivatives of
            %  that field's state transition function relative to the state
            %  vector. Here M is the number of elements in a measurement
            %  from this motion model.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %  See also: insEKF

            idx = stateinfo(filt);
            state = filt.State;
            angvelBodyX = state(idx.AngularVelocity(1));
            angvelBodyY = state(idx.AngularVelocity(2));
            angvelBodyZ = state(idx.AngularVelocity(3));
            q0 = state(idx.Orientation(1));
            q1 = state(idx.Orientation(2));
            q2 = state(idx.Orientation(3));
            q3 = state(idx.Orientation(4));
            oidx = idx.Orientation;
            avidx = idx.AngularVelocity;
            vidx = idx.Velocity;
            accidx = idx.Acceleration;
            
            N = numel(state);
            % Orientation
            dorientfuncdx = zeros(4,N, 'like', state);
            dorientfuncdx(1,oidx) = [0, -angvelBodyX/2, -angvelBodyY/2, -angvelBodyZ/2];
            dorientfuncdx(1,avidx) = [-q1/2, -q2/2, -q3/2];
            
            dorientfuncdx(2,oidx) = [angvelBodyX/2, 0, angvelBodyZ/2, -angvelBodyY/2];
            dorientfuncdx(2,avidx) = [q0/2, -q3/2, q2/2];
            
            dorientfuncdx(3,oidx) = [angvelBodyY/2, -angvelBodyZ/2, 0, angvelBodyX/2];
            dorientfuncdx(3,avidx) = [q3/2, q0/2, -q1/2];
            
            dorientfuncdx(4,oidx) = [angvelBodyZ/2, angvelBodyY/2, -angvelBodyX/2, 0];
            dorientfuncdx(4,avidx) = [-q2/2, q1/2, q0/2];
           
            % AngularVelocity
            davfuncdx = zeros(3,N, 'like', state);
           
            % Position
            dposfuncdx = zeros(3,N, 'like', state);
            dposfuncdx(1,vidx) = [1, 0, 0];
            dposfuncdx(2,vidx) = [0, 1, 0];
            dposfuncdx(3,vidx) = [0, 0, 1];
           
            % Velocity
            dvelfuncdx = zeros(3,N, 'like', state);
            dvelfuncdx(1,accidx) = [1, 0, 0];
            dvelfuncdx(2,accidx) = [0, 1, 0];
            dvelfuncdx(3,accidx) = [0, 0, 1];
           
            % Acceleration
            daccfuncdx = zeros(3,N, 'like', state);
     
            dfdx = struct('Orientation' ,dorientfuncdx, ...
                'AngularVelocity', davfuncdx, ...
                'Position', dposfuncdx, ...
                'Velocity', dvelfuncdx, ...
                'Acceleration', daccfuncdx);
            
        end
        
    end


end
