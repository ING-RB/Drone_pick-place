classdef INSMotionModel < positioning.internal.INSModelShared 
%INSMOTIONMODEL Base class for motion models used with INS filters
%   The INSMotionModel defines the interface for motion model classes that
%   can be used with an INS fusion filter, like the insEKF.
%
%   To define a new motion : 
%       * Inherit from this class and implement at least a modelstates and
%         a stateTransition method. 
%       * Optionally, implement a stateTransitionJacobian method.
%         Alternatively, a numeric Jacobian will be computed internally.
%
%   See also: insEKF, positioning.INSSensorModel       
%

%   Copyright 2021 The MathWorks, Inc.      

%#codegen


    %%%% Required methods %%%%
    methods (Abstract)
        % MODELSTATES Define the tracked states for this motion model.
        %   MODELSTATES returns a scalar struct which describes the states used
        %   by the motion model and tracked by the insEKF filter. The field
        %   names describe the state quantities accessible through the
        %   stateparts function. The values of the struct determine the size
        %   and default values of the state vector. The input FILT is the
        %   insEKF object. The input OPTS is the insOptions used to build
        %   the filter.
        %
        %   Example implementation:
        %       function s = modelstates(filt, opts)
        %           s = struct('Position', zeros(1,3, opts.Datatype));
        %       end
        %
        %  See also: insEKF, insEKF/stateparts
        s = modelstates(filt, opts)    
    end
    methods (Abstract)
        % STATETRANSITION State transition function for motion model
        %   STATETRANSITION returns a struct with identical fields, and
        %   field sizes as MODELSTATES. The struct describes the per-state
        %   transition function STATESDOT for the motion model MMODEL. The
        %   STATESDOT struct contains the time derivative of the state
        %   transition function. That is, for a
        %   state vector STATE:
        %   
        %       STATESDOT.(MODELSTATE_i) = dF(MODELSTATE_i, dt, varargin)/dt
        %   for some state transition function F.
        %
        %   This function is called by the insEKF filter FILT when the PREDICT method
        %   of the FILT function is called. The FILT input is a handle to the calling
        %   insEKF filter. The DT and VARARGIN inputs are the corresponding inputs to
        %   the PREDICT method.
        %
        %   See also: insEKF, positioning.INSMotionModel/modelstates
        statesdot = stateTransition(mmodel, filt, dt, varargin);
    end

    methods
        %STATETRANSITIONJACOBIAN Jacobian of the state transition function
        %   STATETRANSITIONJACOBIAN returns a struct DFDX with identical
        %   fields as MODELSTATES. The structure describes the Jacobian of the
        %   per-state transition function relative to the filter FILT state
        %   vector STATE property. Each field value of STATESDOT should be
        %   a S-by-NUMEL(STATE) array of partial derivatives of that
        %   field's state transition function relative to STATE. Here S is
        %   the number of elements of a MODELSTATE field. The returned DFDX
        %   struct contains the Jacobian
        %  
        %   dfdx.(MODELSTATE_i)(1,j) = dF(MODELSTATE_i,dt,varargin)/dSTATE(j)
        %
        %   This function is called by the insEKF filter FILT when the PREDICT method of
        %   the FILT function is called. The FILT input is a handle to the calling insEKF.
        %   The DT and VARARGIN inputs are the corresponding inputs to the PREDICT method.
        %   
        %   Implementing this method is optional. If this method is not implemented a
        %   numerical Jacobian will be used instead. 
        %
        %   See also: insEKF, positioning.INSMotionModel/stateTransition
        function dfdx = stateTransitionJacobian(mmodel, filt, dt, varargin)   
            dfdx = ...
                stateTransitionJacobian@positioning.internal.INSModelShared(...
                mmodel, filt, dt, varargin{:});
        end
    end
end
