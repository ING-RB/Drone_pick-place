function [smoothState, smoothCov] = rtsSmooth(filt, state, statecov, timestamps)
%   This function is for internal use only. It may be removed in the future.
%RTSSMOOTH Rauch-Tung-Striebel smoothing
%   Smooth states using an RTS smoother
%

%   Copyright 2022 The MathWorks, Inc.    

%#codegen 

    smoothState = zeros(size(state), 'like', state);
    smoothCov = zeros(size(statecov), 'like', statecov);
    Q = filt.AdditiveProcessNoise;
    % initialize
    smoothState(end,:) = state(end,:);
    smoothCov(:,:,end) = statecov(:,:,end);

    timediff = diff(timestamps);
    dt = seconds(timediff);
    N = size(state,1);

    % Walk backwards over the state and state covariance.
    % The smoothed state at time k is function of
    %   the estimated state at k+1
    %   the smoothed state at time k+1
    %   the state transition and state transition jacobian of the estimate
    %       at time k+1 and the dt from k to k+1. 
    for ii=N-1:-1:1
        prevSmoothState = smoothState(ii+1,:).';
        prevSmoothCov = smoothCov(:,:,ii+1);
        Pfwd = statecov(:,:,ii+1);
        xfwd = state(ii+1,:).';

        filt.State = xfwd;
        [fdot, Fjac] = computeStateDerivative(filt, dt(ii));

        K = Q/Pfwd; 
        Prevdot = -(Fjac + K)*prevSmoothCov - prevSmoothCov*(Fjac + K).' + Q;
        xrevdot = -(Fjac + K)*(prevSmoothState - xfwd) - fdot;

        s = filt.eulerIntegrate(prevSmoothState, xrevdot, dt(ii));
        smoothState(ii,:) = repairQuaternion(filt, s);
        smoothCov(:,:,ii) = filt.eulerIntegrate(prevSmoothCov, Prevdot, dt(ii));
    end

end
