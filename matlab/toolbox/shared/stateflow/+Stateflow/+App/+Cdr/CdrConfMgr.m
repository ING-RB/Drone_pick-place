classdef CdrConfMgr < handle
%

%   Copyright 2017-2019 The MathWorks, Inc.
    properties
        animationDelay
        logData
        configureInstance
        cleanMLCode %no debug, no animation
        useCustomObserver
        inlineLevel;
        dispatch;
        saveLoad;
        emlBasedParsing
        animationClass
    end
    properties (Hidden = true)
        % Testing specific flags (internal)
        isUnderTesting
        isAnimationTesting
        isDebuggerTesting
        debuggerTestingCB
        testingUnhandledErrors
        generatedCodeDebugging
        makeCodeReadable
        versionCheck
        traceInMLC
        viewer
        forceSkipToolBarsrunStateflowTimercbReturnLogic
    end
    methods (Access = private)
        function this = CdrConfMgr
        %Animation class
            this.animationClass = 'Stateflow.internal.getRuntime';

            %adds save/load functions
            this.saveLoad = false;

            this.cleanMLCode = false;%no debug, no animation, no coder.target

            %adds logData functions
            this.logData = false;


            this.makeCodeReadable = false;

            %level 1 to 5 of degrees of inline as follows and can be set using this.inlineLevel
            %level 1 : everything possible is hoisted using a function. e.g. In
            %this level, there will be following functions,
            %For each State: enterAtomic, enterInternal, enterTotal, during, exitAtomic, exitInternal, exitTotal,
            %For each State: defaultTransitionPath, innerTransitionPath, outerTransitionPath
            %For each transition:  transitionCondition, transitionAction
            %level 2 :  level 1 minus transitionCondition, transitionAction
            %level 3 :  level 2 minus defaultTransitionPath, innerTransitionPath, outerTransitionPath
            %level 4 :  level 2 minus enterTotal and exitTotal i.e. five functions per state and no functions for transition
            %level 5 :  one single step function
            this.inlineLevel = 2; %minimum 2 required
            this.dispatch = false; %is enabled, in the inline level5, it will use dispatching instead of inlining

            %delay for animation
            this.animationDelay = 0.01;

            % Do not emit initialization of the animation observer class
            % in the constructor
            this.useCustomObserver = false;

            %check version of the model and throw error if older /
            % different than latest version of Stateflow for Matlab
            this.versionCheck = true;

            % Testing specific flags
            % isUnderTesting is set for any test run. This arises due to
            % recent changes to test - opening renamed file throws warning.
            % and increasing the version number throws warning
            this.isUnderTesting = false;

            % isAnimationTesting is used by TestCases under
            % test/toolbox/stateflow/sf_in_matlab/cdr/positive to verify
            % animation highlighting
            this.isAnimationTesting = false;

            % isDebuggerTesting is used by TestCases under
            % test/toolbox/stateflow/sf_in_matlab/cdr/positive to verify
            % debugging infrastructure
            this.isDebuggerTesting = false;
            this.debuggerTestingCB = [];



            this.emlBasedParsing = false;


            this.testingUnhandledErrors = false;


            %to enable debugging generated code for developers
            this.generatedCodeDebugging = false;


            %adds comments to trace generated c/c++ code back to SFX Model
            this.traceInMLC = true;

            this.configureInstance = false;

            this.viewer = true;

            this.forceSkipToolBarsrunStateflowTimercbReturnLogic = false;
        end
    end
    methods

        function disableLintChecks(~)
            sf('SetLintStatus', false);
        end


        function enableLintChecks(~)
            sf('SetLintStatus', true);
        end




        function enableGeneratedCodeDebuggingForDev(self)
            self.generatedCodeDebugging = true;
            eval('sf(''unsubscribeAllDebugEventsListeners'');');
            eval('sf(''subscribeToDebugEvents'', ''_sfxdebug_.m'', ''Stateflow.App.Cdr.Runtime.InstanceIndRuntime.debugEventCallback'');');
        end
        function disableGeneratedCodeDebuggingForDev(self)
            self.generatedCodeDebugging = false;
            eval('sf(''unsubscribeAllDebugEventsListeners'');');
            eval('sf(''subscribeToDebugEvents'', ''.sfx'', ''Stateflow.App.Cdr.Runtime.InstanceIndRuntime.debugEventCallback'');');
        end

    end

    methods (Static)
        function obj = getInstance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = Stateflow.App.Cdr.CdrConfMgr;
            end
            obj = localObj;
            %             mlock;
        end
        function generateCleanMATLABCode(val)
            confMgr = Stateflow.App.Cdr.CdrConfMgr.getInstance;
            if val
                confMgr.cleanMLCode = val;
                confMgr.makeCodeReadable = true;
                oldWarningStatus = warning('backtrace');
                warning('off', 'backtrace');
                warningId ='MATLAB:sfx:NonInstrumentedModeEnabled';
                warning(warningId, getString(message(warningId)));
                warning(oldWarningStatus.state, 'backtrace');
            else
                confMgr.cleanMLCode = val;
                confMgr.makeCodeReadable = true;
            end
        end
    end
end
