classdef QualificationDelegate < matlab.mixin.Copyable
    % This class is undocumented and may change in a future release.

    % Copyright 2011-2024 The MathWorks, Inc.

    properties(Abstract, Constant, Access=protected)
        Type

        % This private Constant property is for use in qualifyTrue, which should be
        % as performant as possible, and thus cannot pay the overhead of
        % constructing a new instance for every call. Note each subclass needs one since
        % the IsTrue constraints need different constraint alias (verifyTrue/assertTrue/etc).
        IsTrueConstraint
    end

    properties (Access = private, Transient)
        EvaluatingAdditionalDiagnostics = false;
    end
    
    methods(Abstract)
        doFail(delegate, qualificationFailedExceptionMarker);
    end

    methods(Static, Access=protected)
        function constraint = generateIsTrueConstraint(type)
            import matlab.unittest.constraints.IsTrue;
            constraint = addCasualDiagnosticDecorator(IsTrue,...
                [type 'True'], {});
        end
    end

    methods(Sealed)
        function pass(~, qualifiable, notificationData, actual, constraint, varargin)
            import matlab.unittest.qualifications.QualificationEventData;
            import matlab.unittest.internal.qualifications.QualificationFailedExceptionMarker;
            import matlab.unittest.diagnostics.Diagnostic

            stack = dbstack('-completenames');
            marker = QualificationFailedExceptionMarker;
            diagData = notificationData.DiagnosticData(qualifiable);
            additionalDiagnostics = Diagnostic.empty(1,0);
            eventData = QualificationEventData(stack, actual, constraint, marker, diagData, additionalDiagnostics, varargin{:});
            notificationData.NotifyPassed(qualifiable, eventData);
        end

        function fail(delegate, qualifiable, notificationData, actual, constraint, varargin)
            import matlab.unittest.qualifications.QualificationEventData;
            import matlab.unittest.internal.qualifications.QualificationFailedExceptionMarker;

            stack = dbstack('-completenames');
            marker = QualificationFailedExceptionMarker;
            diagData = notificationData.DiagnosticData(qualifiable);
            cl = onCleanup.empty(1,0);
            if ~delegate.EvaluatingAdditionalDiagnostics
                additionalDiagnostics = notificationData.OnFailureDiagnostics(qualifiable);
                delegate.setEvaluatingAdditionalDiagnostics(true);
                cl = onCleanup(@()setEvaluatingAdditionalDiagnostics(delegate,false));
            else
                additionalDiagnostics = matlab.unittest.diagnostics.Diagnostic.empty(1,0);
            end
            eventData = QualificationEventData(stack, actual, constraint, marker, diagData, additionalDiagnostics, varargin{:});

            % diagnose the onFailureDiagnostics immediately
            eventData.AdditionalDiagnosticResults;
            delete(cl);
            notificationData.NotifyFailed(qualifiable, eventData);
            qualifiable.invokePostFailureEventCallbacks_(struct( ...
                "Type",string(eventData.EventName), "Marker",marker));

            cleaner = matlab.unittest.internal.setStopIfCaughtErrorInTestRunner(false); %#ok<NASGU> 
            delegate.doFail(marker);
        end
    end

    methods
        function qualifyThat(delegate, qualifiable, notificationData, actual, constraint, varargin)
            narginchk(5,6);

            if isa(actual, 'matlab.unittest.constraints.ActualValueProxy')
                result = actual.satisfiedBy(constraint);
            elseif isa(constraint, 'matlab.unittest.constraints.Constraint')
                result = constraint.satisfiedBy(actual);
            else
                validateattributes(constraint, {'matlab.unittest.constraints.Constraint'},{},'', 'constraint');
            end

            if islogical(result) && isscalar(result) && result
                if notificationData.HasPassedListener(qualifiable)
                    delegate.pass(qualifiable, notificationData, actual, constraint, varargin{:});
                end
            else
                delegate.fail(qualifiable, notificationData, actual, constraint, varargin{:});
            end
        end

        function qualifyFail(delegate, qualifiable, notificationData, varargin)
            import matlab.unittest.internal.constraints.FailingConstraint;
            fail = addCasualDiagnosticDecorator(FailingConstraint,...
                [delegate.Type 'Fail'], {});
            delegate.qualifyThat(qualifiable, notificationData, [], fail, varargin{:});
        end

        function qualifyTrue(delegate, qualifiable, notificationData, actual, varargin)
            delegate.qualifyThat(qualifiable, notificationData, actual, delegate.IsTrueConstraint, varargin{:});
        end

        function qualifyFalse(delegate, qualifiable, notificationData, actual, varargin)
            import matlab.unittest.constraints.IsFalse;
            isFalse = addCasualDiagnosticDecorator(IsFalse,...
                [delegate.Type 'False'], {});
            delegate.qualifyThat(qualifiable, notificationData, actual, isFalse, varargin{:});
        end

        function qualifyEqual(delegate, qualifiable, notificationData, actual, expected, varargin)
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            import matlab.unittest.constraints.RelativeTolerance;
            import matlab.internal.datatypes.isScalarText;

            % Handle optional diagnostic outside of inputParser
            diag = {};
            numOptionalInputs = numel(varargin);
            if mod(numOptionalInputs, 2) == 1
                % An odd number of inputs implies a diagnostic was specified. Could be any of:
                % qualifyEqual(actual, expected, diagnostic)
                % qualifyEqual(actual, expected, diagnostic, <name-value pairs>)
                % qualifyEqual(actual, expected, <name-value pairs>, diagnostic)  % Backward compatibility

                if numOptionalInputs > 1 && ...
                        isScalarText(varargin{2}, false) % Assume the AbsTol and RelTol values are never text
                    % diagnostic is the first optional input
                    diag = varargin(1);
                    varargin(1) = [];
                else
                    % diagnostic is the last input
                    diag = varargin(end);
                    varargin(end) = [];
                end
            end

            % Tolerance constructors handle input validation; none needed here
            p = inputParser;
            p.addParameter('AbsTol',[]);
            p.addParameter('RelTol',[]);
            p.parse(varargin{:});

            absTolSpecified = ~any(strcmp('AbsTol', p.UsingDefaults));
            relTolSpecified = ~any(strcmp('RelTol', p.UsingDefaults));

            constraint = IsEqualTo(expected);
            additionalArgs = {expected};
            if absTolSpecified && relTolSpecified
                % AbsoluteTolerance "or" RelativeTolerance
                constraint = constraint.within(AbsoluteTolerance(p.Results.AbsTol) | ...
                    RelativeTolerance(p.Results.RelTol));
                additionalArgs = [additionalArgs,{'AbsTol',p.Results.AbsTol,...
                    'RelTol',p.Results.RelTol}];
            elseif relTolSpecified
                % RelativeTolerance only
                constraint = constraint.within(RelativeTolerance(p.Results.RelTol));
                additionalArgs = [additionalArgs,{'RelTol',p.Results.RelTol}];
            elseif absTolSpecified
                % AbsoluteTolerance only
                constraint = constraint.within(AbsoluteTolerance(p.Results.AbsTol));
                additionalArgs = [additionalArgs,{'AbsTol',p.Results.AbsTol}];
            end

            constraint = addCasualDiagnosticDecorator(constraint,...
                [delegate.Type 'Equal'], additionalArgs);
            delegate.qualifyThat(qualifiable, notificationData, actual, constraint, diag{:});
        end

        function qualifyNotEqual(delegate, qualifiable, notificationData, actual, notExpected, varargin)
            import matlab.unittest.constraints.IsEqualTo;
            isNotEqualTo = addCasualDiagnosticDecorator(~IsEqualTo(notExpected),...
                [delegate.Type 'NotEqual'], {notExpected});
            delegate.qualifyThat(qualifiable, notificationData, actual, isNotEqualTo, varargin{:});
        end

        function qualifySameHandle(delegate, qualifiable, notificationData, actual, expectedHandle, varargin)
            import matlab.unittest.constraints.IsSameHandleAs;
            isSameHandleAs = addCasualDiagnosticDecorator(IsSameHandleAs(expectedHandle),...
                [delegate.Type 'SameHandle'],{expectedHandle});
            delegate.qualifyThat(qualifiable, notificationData, actual, isSameHandleAs, varargin{:});
        end

        function qualifyNotSameHandle(delegate, qualifiable, notificationData, actual, notExpectedHandle, varargin)
            import matlab.unittest.constraints.IsSameHandleAs;
            isNotSameHandleAs = addCasualDiagnosticDecorator(~IsSameHandleAs(notExpectedHandle),...
                [delegate.Type 'NotSameHandle'], {notExpectedHandle});
            delegate.qualifyThat(qualifiable, notificationData, actual, isNotSameHandleAs, varargin{:});
        end

        function varargout = qualifyError(delegate, qualifiable, notificationData, actual, errorClassOrID, varargin)
            import matlab.unittest.constraints.Throws;
            throwsWithOutputs = Throws(errorClassOrID, 'WhenNargoutIs', nargout);
            throwsWithOutputs = addCasualDiagnosticDecorator(throwsWithOutputs,...
                [delegate.Type 'Error'], {errorClassOrID});
            delegate.qualifyThat(qualifiable, notificationData, actual, throwsWithOutputs, varargin{:});
            varargout = throwsWithOutputs.RootConstraint.FunctionOutputs;
        end

        function varargout = qualifyWarning(delegate, qualifiable, notificationData, actual, warningIdObject, varargin)
            import matlab.unittest.constraints.IssuesWarnings;
            % qualifyWarning
            %   warningIdObject - Can be either one warning ID, multiple IDs,
            %                     or a message object.
            warningIdObjectTmp = warningIdObject;
            if ~isa(warningIdObject,'message')
                warningIdObjectTmp = cellstr(warningIdObject);
            end
            issuesWarningsWithOutputs = IssuesWarnings(warningIdObjectTmp, 'WhenNargoutIs',nargout);
            issuesWarningsWithOutputs = addCasualDiagnosticDecorator(issuesWarningsWithOutputs,...
                [delegate.Type 'Warning'], {warningIdObject});
            delegate.qualifyThat(qualifiable, notificationData, actual, issuesWarningsWithOutputs, varargin{:});
            varargout = issuesWarningsWithOutputs.RootConstraint.FunctionOutputs;
        end

        function varargout = qualifyWarningFree(delegate, qualifiable, notificationData, actual, varargin)
            import matlab.unittest.constraints.IssuesNoWarnings;
            issuesNoWarningsWithOutputs = IssuesNoWarnings('WhenNargoutIs',nargout);
            issuesNoWarningsWithOutputs = addCasualDiagnosticDecorator(issuesNoWarningsWithOutputs,...
                [delegate.Type 'WarningFree'], {});
            delegate.qualifyThat(qualifiable, notificationData, actual, issuesNoWarningsWithOutputs, varargin{:});
            varargout = issuesNoWarningsWithOutputs.RootConstraint.FunctionOutputs;
        end

        function qualifyEmpty(delegate, qualifiable, notificationData, actual, varargin)
            import matlab.unittest.constraints.IsEmpty;
            isEmpty = addCasualDiagnosticDecorator(IsEmpty,...
                [delegate.Type 'Empty'], {});
            delegate.qualifyThat(qualifiable, notificationData, actual, isEmpty, varargin{:});
        end

        function qualifyNotEmpty(delegate, qualifiable, notificationData, actual, varargin)
            import matlab.unittest.constraints.IsEmpty;
            isNotEmpty = addCasualDiagnosticDecorator(~IsEmpty,...
                [delegate.Type 'NotEmpty'], {});
            delegate.qualifyThat(qualifiable, notificationData, actual, isNotEmpty, varargin{:});
        end

        function qualifySize(delegate, qualifiable, notificationData, actual, expectedSize, varargin)
            import matlab.unittest.constraints.HasSize;
            hasSize = addCasualDiagnosticDecorator(HasSize(expectedSize),...
                [delegate.Type 'Size'], {expectedSize});
            delegate.qualifyThat(qualifiable, notificationData, actual, hasSize, varargin{:});
        end

        function qualifyLength(delegate, qualifiable, notificationData, actual, expectedLength, varargin)
            import matlab.unittest.constraints.HasLength;
            hasLength = addCasualDiagnosticDecorator(HasLength(expectedLength),...
                [delegate.Type 'Length'], {expectedLength});
            delegate.qualifyThat(qualifiable, notificationData, actual, hasLength, varargin{:});
        end

        function qualifyNumElements(delegate, qualifiable, notificationData, actual, expectedElementCount, varargin)
            import matlab.unittest.constraints.HasElementCount;
            hasElementCount = addCasualDiagnosticDecorator(HasElementCount(expectedElementCount),...
                [delegate.Type 'NumElements'], {expectedElementCount});
            delegate.qualifyThat(qualifiable, notificationData, actual, hasElementCount, varargin{:});
        end

        function qualifyGreaterThan(delegate, qualifiable, notificationData, actual, floor, varargin)
            import matlab.unittest.constraints.IsGreaterThan;
            isGreaterThan = addCasualDiagnosticDecorator(IsGreaterThan(floor),...
                [delegate.Type 'GreaterThan'], {floor});
            delegate.qualifyThat(qualifiable, notificationData, actual, isGreaterThan, varargin{:});
        end

        function qualifyGreaterThanOrEqual(delegate, qualifiable, notificationData, actual, floor, varargin)
            import matlab.unittest.constraints.IsGreaterThanOrEqualTo;
            isGreaterThanOrEqualTo = addCasualDiagnosticDecorator(IsGreaterThanOrEqualTo(floor),...
                [delegate.Type 'GreaterThanOrEqual'], {floor});
            delegate.qualifyThat(qualifiable, notificationData, actual, isGreaterThanOrEqualTo, varargin{:});
        end

        function qualifyLessThan(delegate, qualifiable, notificationData, actual, ceiling, varargin)
            import matlab.unittest.constraints.IsLessThan;
            isLessThan = addCasualDiagnosticDecorator(IsLessThan(ceiling),...
                [delegate.Type 'LessThan'], {ceiling});
            delegate.qualifyThat(qualifiable, notificationData, actual, isLessThan, varargin{:});
        end

        function qualifyLessThanOrEqual(delegate, qualifiable, notificationData, actual, ceiling, varargin)
            import matlab.unittest.constraints.IsLessThanOrEqualTo;
            isLessThanOrEqualTo = addCasualDiagnosticDecorator(IsLessThanOrEqualTo(ceiling),...
                [delegate.Type 'LessThanOrEqual'], {ceiling});
            delegate.qualifyThat(qualifiable, notificationData, actual, isLessThanOrEqualTo, varargin{:});
        end

        function qualifyReturnsTrue(delegate, qualifiable, notificationData, actual, varargin)
            import matlab.unittest.constraints.ReturnsTrue;
            returnsTrue = addCasualDiagnosticDecorator(ReturnsTrue,...
                [delegate.Type 'ReturnsTrue'], {});
            delegate.qualifyThat(qualifiable, notificationData, actual, returnsTrue, varargin{:});
        end

        function qualifyInstanceOf(delegate, qualifiable, notificationData, actual, expectedBaseClass, varargin)
            import matlab.unittest.constraints.IsInstanceOf;
            isInstanceOf = addCasualDiagnosticDecorator(IsInstanceOf(expectedBaseClass),...
                [delegate.Type 'InstanceOf'], {expectedBaseClass});
            delegate.qualifyThat(qualifiable, notificationData, actual, isInstanceOf, varargin{:});
        end

        function qualifyClass(delegate, qualifiable, notificationData, actual, expectedClass, varargin)
            import matlab.unittest.constraints.IsOfClass;
            isOfClass = addCasualDiagnosticDecorator(IsOfClass(expectedClass),...
                [delegate.Type 'Class'], {expectedClass});
            delegate.qualifyThat(qualifiable, notificationData, actual, isOfClass, varargin{:});
        end

        function qualifySubstring(delegate, qualifiable, notificationData, actual, substring, varargin)
            import matlab.unittest.constraints.ContainsSubstring;
            containsSubstring = addCasualDiagnosticDecorator(ContainsSubstring(substring),...
                [delegate.Type 'Substring'], {substring});
            delegate.qualifyThat(qualifiable, notificationData, actual, containsSubstring, varargin{:});
        end

        function qualifyMatches(delegate, qualifiable, notificationData, actual, expression, varargin)
            import matlab.unittest.constraints.Matches;
            matches = addCasualDiagnosticDecorator(Matches(expression),...
                [delegate.Type 'Matches'], {expression});
            delegate.qualifyThat(qualifiable, notificationData, actual, matches, varargin{:});
        end
    end

    methods(Access=private)
        function setEvaluatingAdditionalDiagnostics(delegate, value)
            delegate.EvaluatingAdditionalDiagnostics = value;
        end
    end
end

function constraint = addCasualDiagnosticDecorator(constraint, methodName, additionalArgs)
% addCasualDiagnosticDecorator
%   methodName     - name of the casual method (ex: 'verifyEqual')
%   additionalArgs - input arguments provided to casual method besides the
%                    actual value and optional test diagnostic
import matlab.unittest.internal.constraints.CasualDiagnosticDecorator;
constraint = CasualDiagnosticDecorator(constraint,...
    ['matlab.unittest.TestCase.' methodName], ...
    additionalArgs);
end

% LocalWords:  performant completenames el Teardownable Tmp
