classdef (Abstract) RetrodictionFilter < matlabshared.tracking.internal.OOSMFilter
%RetrodictionFilter  Interface definition for a retrodiction filter
%
% The RetrodictionFilter is an abstract class that defines the interface
% that every tracking filter must implement to enable retrodiction. 
% Retrodiction is a technique to handle out-of-sequence measurements (OOSM)
% without the need to reprocess all the measurements.
% Inherit from this class and implement these methods to be able to work
% with multi-object trackers that use retrodiction as OOSM technique.
%
% Private methods that must be implemented are:
%    retrodict         - Retrodict the filter to a previous time
%    retroCorrect      - Correct the filter with an OOSM using retrodiction
%    retroCorrectJPDA  - Correct the filter with OOSMs using retrodiction
%                        and probabilistic weights.
%
% See also: AbstractTrackingFilter

% Copyright 2021 The MathWorks, Inc.
%#codegen

    properties (Access = {?matlabshared.tracking.internal.OOSMFilter, ...
            ?matlab.unittest.TestCase})
        pWasRetrodicted = false
        pCrossCov
        pDFDX
    end

    % Public methods that must be implemented
    methods(Abstract)
        [retroState, retroCov, success] = retrodict(obj,dt)
        % RETRODICT Retrodict the filter to a previous time
        % [retroState, retroCov] = RETRODICT(obj,dt) retrodicts
        % (predicts backward in time) the filter by dt seconds. dt must
        % be a nonpositive time difference from the current filter time
        % to the time at which an out-of-sequence measurement was taken.
        %
        % retroState is the retrodicted state to OOSM time, kappa, xhat(kappa|k)
        % retroCov is the retrodicted state covariance to OOSM time, P(kappa|k)
        %
        % If the filter cannot be retrodicted to the time of the OOSM,
        % because its history does not extend that far back, a warning is
        % provided. You can check the status of the retrodiction using
        % [..., success] = ... where success is true if the filter is
        % retrodicted.
        
        
        [x_retroCorr, P_retroCorr] = retroCorrect(obj,z,varargin)
        % retroCorrect Correct the filter with an OOSM using retrodiction
        % [x_retroCorr, P_retroCorr] = retroCorrect(obj,z) corrects the
        % filter with the out-of-sequence measurement (OOSM), z. You
        % must first call the retrodict method to predict the filter
        % backwards to the time of the measurement.
        %
        % ... = retroCorrect(..., measurementParameters) additionally,
        % allows you to pass measurement parameters.
        
        [x_retroCorr, P_retroCorr] = retroCorrectJPDA(obj,z,beta,varargin)
        % retroCorrect Correct the filter with an OOSM using retrodiction
        % [x_retroCorr, P_retroCorr] = retroCorrectJPDA(obj,z, beta)
        % corrects the filter with a matrix of out-of-sequence measurements
        % (OOSMs), z and a vector of association probabilities, beta. You
        % must first call the retrodict method to predict the filter
        % backwards to the time of the measurement.
        %
        % ... = retroCorrectJPDA(..., measurementParameters) additionally,
        % allows you to pass measurement parameters.
    end

    %Abstract implementation methods, which need to be exposed to filters
    %that hold other filters
    methods (Abstract, Access = ...
            {?matlabshared.tracking.internal.RetrodictionFilter, ...
            ?matlabshared.tracking.internal.AbstractContainsFilters, ...
            ?matlab.unittest.TestCase})
        [retroState, retroCov] = retrodictionImpl(obj,dt,tk,tkappa,distk,tl,distl)
        % [retroState, retroCov] = retrodictionImpl(obj,dt,tk,tkappa,distk,tl,distl)
        % Defines the Gaussian retrodiction implementation method. 
        % Inputs:
        %    dt     - delta time from current time to OOSM time (negative)
        %    tk     - last update time saved by the filter
        %    tkappa - OOSM timestamp
        %    distk  - filter distribution at time k
        %    tl     - update timestamp immediately before OOSM
        %    distl  - filter distribution at time l
        % Outputs:
        %    retroState - filter state retrodicted to OOSM time
        %    retroCov   - filter covariance retrodicted to OOSM time

        retroCorrectImpl(obj,z,distk,varargin)
        % retroCorrectImpl(obj,z,distk,varargin)
        % Inputs:
        %    z        - out of sequence measurement
        %    distk    - filter distribution at time k (last corrected time)
        %    varargin - measurement parameters (only used in EKF)
        
        retroCorrectJPDAImpl(obj,z,beta,distk,varargin)
        % retroCorrectJPDAImpl(obj,z,distk,varargin)
        % Inputs:
        %    z        - out of sequence measurements
        %    beta     - probability association of measurements
        %    distk    - filter distribution at time k (last corrected time)
        %    varargin - measurement parameters (only used in EKF)
    end
    
    methods(Access = protected)
        function oosmGroup = getPropertyGroups(~)
            oosmGroup = matlab.mixin.util.PropertyGroup({'MaxNumOOSMSteps'});
        end
    end
    methods(Access = {?matlabshared.tracking.internal.OOSMFilter, ...
            ?matlab.unittest.TestCase})
        function updateHistoryAfterCorrection(obj)
            updateHistoryAfterCorrection@matlabshared.tracking.internal.OOSMFilter(obj);
            obj.pWasRetrodicted = false;
        end
        
        function syncRetroFilter(this,that)
            syncOOSMFilter(this,that);
            if coder.internal.is_defined(that.pCrossCov)
                this.pCrossCov = that.pCrossCov;
                this.pDFDX = that.pDFDX;
            end
            this.pWasRetrodicted = that.pWasRetrodicted;
        end
        
        function cloneRetroFilter(obj2, obj)
            cloneOOSMFilter(obj2,obj);
            syncRetroFilter(obj2,obj);
        end
        
        function updateRetrodictionStateAfterPrediction(obj,varargin)
            
            % To update the retrodiction filter, we expect varargin to be
            % either empty or have one element: dt. If empty, dt = 1
            
            % After the first call to predict, the filter must lock its
            % pMaxNumOOSMSteps.
            assertMaxNumDefined(obj);
            usesOOSM = obj.MaxNumOOSMSteps > 0;
            if ~usesOOSM
                return
            end
            tooManyInputs = numel(varargin) > 1;
            oneInput = numel(varargin)==1;
            cond = tooManyInputs || ... % Error on more than one input
                oneInput && ~isscalar(varargin{1}) || ... % Or one nonscalar input 
                oneInput && isscalar(varargin{1}) && varargin{1} < 0; % Or scalar dt < 0
            coder.internal.errorIf(cond, 'shared_tracking:OOSMFilter:PredictArgs',...
                'MaxNumOOSMSteps','predict');
            
            if isempty(varargin)
                dt = ones(1,1,'like',obj.pCorrectionTimestamps);
            else
                dt = varargin{1};
            end
            
            if coder.internal.is_defined(obj.pPredictionDeltaTFromLastCorrection)
                obj.pPredictionDeltaTFromLastCorrection = obj.pPredictionDeltaTFromLastCorrection + dt;
            else
                obj.pPredictionDeltaTFromLastCorrection = dt;
            end
            obj.pWasRetrodicted = false;
        end
        
        function validateRetrodict(obj, dt)
            % Shared validation for retrodict interface
            validateattributes(dt, {'double','single'}, ...
               {'real', 'finite', 'nonsparse', 'scalar', '<=', 0}, 'retrodict', 'dt');
           
           % Retrodict cannot be used with MaxNumOOSMSteps == 0
           coder.internal.assert(obj.MaxNumOOSMSteps > 0, ...
               'shared_tracking:OOSMFilter:RetrodictionDisabled',...
               'MaxNumOOSMSteps','retrodict');

           % Retrodict cannot be called consecutively
           coder.internal.errorIf(obj.pWasRetrodicted,...
               'shared_tracking:OOSMFilter:RepeatedRetrodiction',...
               'retrodict','retroCorrect','retroCorrectJPDA','correct','correctjpda');
        end

        function [distk,tk, tkappa,success, distl,tl] = getRetrodictQuantities(obj, dt)
            % Common retrodiction steps before retrodictImpl
            tk = max(obj.pCorrectionTimestamps); % Last update time
            currentTime = tk + obj.pPredictionDeltaTFromLastCorrection;
            tkappa = currentTime + dt; % retrodicted time ( should be OOSM time before a retroCorrection)

            if obj.pShouldWarn && tkappa>=tk && coder.target('MATLAB')
                coder.internal.warning('shared_tracking:OOSMFilter:NotRetrodictedEnough',...
                        num2str(obj.pPredictionDeltaTFromLastCorrection),'retrodict',num2str(dt),'correct','correctjpda');
            end

            [~,distk] = fetchDistributionByTime(obj, tk);
            [success,distl,tl] = fetchDistributionByTime(obj, tkappa);
        end
    end
    methods(Access = protected)
        function loadRetroProperties(obj,s)
            % Objects saved before R2021b will not have properties related
            % to retrodiction filter
            if isfield(s,'pWasRetrodicted')
                obj.pWasRetrodicted = s.pWasRetrodicted;
            end
            if isfield(s,'pCrossCov')
                obj.pCrossCov = s.pCrossCov;
            end
            if isfield(s,'pDFDX')
                obj.pDFDX = s.pDFDX;
            end
            loadOOSMProperties(obj,s);
        end
        
        function s = saveRetroProperties(obj, s)
            % If an input struct is provided, append properties on it.
            s = saveOOSMProperties(obj, s);
            s.pWasRetrodicted = obj.pWasRetrodicted;
            s.pCrossCov = obj.pCrossCov;
            s.pDFDX = obj.pDFDX;
        end
    end
end