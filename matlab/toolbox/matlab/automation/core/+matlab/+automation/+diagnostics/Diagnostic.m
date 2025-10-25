classdef Diagnostic < handle & matlab.mixin.Heterogeneous
    % Diagnostic - Fundamental interface for matlab.automation diagnostics
    %
    %   The Diagnostic interface is the means to package diagnostic information.
    %   All diagnostics are built off of the Diagnostic interface, whether
    %   they are user-supplied diagnostics or framework diagnostics.
    %
    %   Classes that derive from the Diagnostic interface encode the
    %   diagnostic actions to be performed and produce a diagnostic result
    %   that can be used by an automation framework, for example, the unit
    %   testing framework, and displayed as appropriate for that framework.
    %
    %   When used with the unit testing framework, in exchange for meeting
    %   this requirement, any Diagnostic implementation can be used directly
    %   with matlab.unittest qualifications, which execute the diagnostic
    %   action and store the result to be utilized by that framework.
    %
    %   As a convenience, the framework creates appropriate diagnostic
    %   instances for raw strings and function handles when they are user
    %   supplied diagnostics. To remain performant, these values are only
    %   converted into Diagnostic instances when a qualification failure
    %   occurs or when the testing framework is explicitly observing
    %   passed qualifications, which the default test runner does not.
    %
    %   Diagnostic properties:
    %       Artifacts      - Artifacts produced during diagnostic evaluation
    %       DiagnosticText - Text result of the diagnostic evaluation
    %
    %   Diagnostic methods:
    %       diagnose    - Execute diagnostic action for the instance
    %       join        - Join multiple diagnostics into a single array
    %
    %   Examples:
    %
    %   import matlab.unittest.constraints.IsEqualTo
    %   import matlab.unittest.TestCase
    %
    %   % Create a TestCase for interactive use
    %   testCase = TestCase.forInteractiveUse;
    %
    %   % Convenience API to create StringDiagnostic upon failure
    %   testCase.verifyThat(1, IsEqualTo(2), 'User supplied Diagnostic');
    %
    %   % Convenience API to create FunctionHandleDiagnostic upon failure
    %   testCase.verifyThat(1, IsEqualTo(2), @() system('ps'));
    %
    %   % Usage of user defined Diagnostic upon failure (see definition below)
    %   testCase.verifyThat(1, IsEqualTo(2), ProcessStatusDiagnostic('Could not close my third party application!'));
    %
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % Diagnostic definition
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   classdef ProcessStatusDiagnostic < matlab.automation.diagnostics.Diagnostic
    %       % ProcessStatusDiagnostic - an example diagnostic
    %       %
    %       %   Simple example to demonstrate how to create a custom
    %       %   diagnostic.
    %
    %       properties
    %
    %           % HeaderText - user-supplied header to display
    %           HeaderText = '(No header supplied)';
    %       end
    %
    %       methods
    %           function diag = ProcessStatusDiagnostic(header)
    %               % Constructor - construct a ProcessStatusDiagnostic
    %               %
    %               %   The ProcessStatusDiagnostic constructor takes an
    %               %   optional header to be displayed along with process
    %               %   information.
    %               diag.HeaderText = header;
    %           end
    %
    %           function diagnose(diag)
    %
    %               [status processInfo] = system('ps');
    %               if (status ~= 0)
    %                   processInfo = sprintf(...
    %                       '!!! Could not obtain status diagnostic information!!! [exit status code: %d]\n%s', ...
    %                       status, processInfo);
    %               end
    %               diag.DiagnosticText = sprintf('%s\n%s', diag.HeaderText, processInfo);
    %           end
    %       end
    %
    %   end %classdef
    %
    %   See also
    %       StringDiagnostic
    %       FunctionHandleDiagnostic
    %       matlab.unittest.constraints.Constraint
    
    %  Copyright 2010-2022 The MathWorks, Inc.
    
    methods(Static)
        function diag = join(varargin)
            % Diagnostic.join      - Join multiple diagnostics into a single array
            %
            %   DIAGARRAY = Diagnostic.join(DIAG1, DIAG2, ... DIAGN) joins together all
            %   of the diagnostic content specified in DIAG1, DIAG2, ... DIAGN into a
            %   single Diagnostic array DIAGARRAY. The elements DIAG1, DIAG2, ... DIAGN
            %   can be Diagnostic instances, strings, character arrays, function
            %   handles, or any other arbitrary values. The resulting diagnostics
            %   become:
            %
            %       Diagnostic      - (unchanged - used as supplied)
            %       string          - matlab.automation.diagnostics.StringDiagnostic
            %       char            - matlab.automation.diagnostics.StringDiagnostic
            %       function handle - matlab.automation.diagnostics.FunctionHandleDiagnostic
            %       arbitrary value - matlab.automation.diagnostics.DisplayDiagnostic
            %
            %   Examples:
            %
            %       % The following example creates a diagnostic array of length 4,
            %       % demonstrating standard Diagnostic conversions. Note:
            %       % MyCustomDiagnostic is for example purposes and is not executable
            %       % code.
            %
            %       import matlab.automation.diagnostics.Diagnostic
            %       import matlab.unittest.constraints.IsTrue
            %
            %       arbitraryValue = 5;
            %       testCase.verifyThat(false, IsTrue, ...
            %           Diagnostic.join(...
            %               "for unit test case",...
            %               'should have been true', ...
            %               @() system('ps'), ...
            %               arbitraryValue, ...
            %               MyCustomDiagnostic));
            %
            %   See also:
            %       matlab.mixin.Heterogeneous
            
            import matlab.automation.diagnostics.Diagnostic;
            
            narginchk(1,Inf);
            
            if ~isa(varargin{1}, 'matlab.automation.diagnostics.Diagnostic')
                varargin{1} = Diagnostic.convertObject('matlab.automation.diagnostic.Diagnostic', varargin{1});
            end
            diag = [varargin{:}];
        end
    end
    
    properties(SetAccess={?matlab.automation.diagnostics.ExtendedDiagnostic})
        % Artifacts - Artifacts produced during diagnostic evaluation
        %
        %   The Artifacts property is an array of FileArtifact instances produced
        %   during the last diagnostic evaluation of the Diagnostic.
        %
        %   See also:
        %       diagnose
        %       matlab.automation.diagnostics.FileArtifact
        %
        Artifacts (1,:) matlab.automation.diagnostics.Artifact = ...
            matlab.automation.diagnostics.FileArtifact.empty(1,0);
    end
    
    properties (Dependent, SetAccess=protected)
        % DiagnosticText - Text result of the diagnostic evaluation
        %
        %   The DiagnosticText property is a character vector which encompasses the
        %   means by which the actual diagnostic information is communicated to
        %   consumers of Diagnostics such as testing frameworks. The property must
        %   be set as a character vector or a scalar string, and should be
        %   populated during the diagnostic evaluation performed in the diagnose
        %   method.
        %
        %   See also:
        %       diagnose
        %
        DiagnosticText;
    end
    
    properties (Hidden, Dependent, SetAccess=protected)
        % DiagnosticResult - DiagnosticResult is not recommended. Use DiagnosticText instead.
        DiagnosticResult;
    end
    
    properties (Hidden, SetAccess=private)
        FormattableDiagnosticText matlab.automation.internal.diagnostics.FormattableString = ...
            getString(message('MATLAB:automation:Diagnostic:NotYetPopulated'));
    end
    
    methods(Abstract)
        % diagnose(diag) - Execute diagnostic action for the instance
        %
        %   The diagnose method is the means by which individual Diagnostic
        %   implementations can perform their respective diagnostic evaluations.
        %   Each concrete implementation is responsible for populating the
        %   DiagnosticText property. Any text printed to the Command
        %   Window during diagnostic evaluation is not considered part of the
        %   diagnostic text result and is ignored by the testing framework.
        %
        %   See also:
        %       DiagnosticText
        %
        diagnose(diag);
    end
    
    methods
        function set.DiagnosticText(diag, text)
            import matlab.automation.internal.mustBeTextScalar;
            if ~isa(text, 'matlab.automation.internal.diagnostics.FormattableString')
                mustBeTextScalar(text,'DiagnosticText');
            end
            diag.FormattableDiagnosticText = text;
        end
        
        function text = get.DiagnosticText(diag)
            text = char(diag.FormattableDiagnosticText);
        end
        
        function set.DiagnosticResult(diag, result)
            diag.DiagnosticText = result;
        end
        
        function result = get.DiagnosticResult(diag)
            result = diag.DiagnosticText;
        end
    end
    
    methods (Hidden, Static, Access=protected, Sealed)
        function convertedObject = convertObject(~, objectToConvert)
            import matlab.automation.diagnostics.StringDiagnostic;
            import matlab.automation.diagnostics.FunctionHandleDiagnostic;
            import matlab.automation.diagnostics.DisplayDiagnostic;
            
            if ischar(objectToConvert) || isstring(objectToConvert)
                convertedObject = StringDiagnostic(objectToConvert);
            elseif isa(objectToConvert,'function_handle')
                convertedObject = FunctionHandleDiagnostic(objectToConvert);
            else
                convertedObject = DisplayDiagnostic(objectToConvert);
            end
        end
        
        function instance = getDefaultScalarElement
            instance = matlab.automation.internal.diagnostics.DiagnosticPlaceholder;
        end
    end
    
    methods(Hidden)
        function diag = toVerbosityAwareDiagnostic(diag)
        end
        
        function diagnoseWith(diag, ~)
            diag.diagnose();
        end
        
        function bool = producesSameResultFor(~,~,~)
            bool = true;
        end
    end
    
    methods(Hidden, Access=protected)
        function diag = Diagnostic
        end
    end
end

% LocalWords:  performant ps DIAGARRAY DIAGN Formattable isstring
