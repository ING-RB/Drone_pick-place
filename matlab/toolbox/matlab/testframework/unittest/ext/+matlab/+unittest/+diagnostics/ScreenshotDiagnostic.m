classdef ScreenshotDiagnostic < matlab.unittest.internal.mixin.PrefixMixin & ...
                                matlab.unittest.diagnostics.ExtendedDiagnostic
    % ScreenshotDiagnostic - A diagnostic that captures the screen to an image file
    %
    %   The ScreenshotDiagnostic class provides a diagnostic that captures all
    %   screens available. A screenshot is captured immediately when a
    %   ScreenshotDiagnostic instance is diagnosed. The DiagnosticText property
    %   contains the name and location of each captured screenshot image file.
    %   The Artifacts property contains a FileArtifact instance associated with
    %   each screenshot image file.
    %
    %   Each screenshot image file is given a name that contains a unique
    %   identifier in order to avoid naming conflicts with other files. The
    %   location of screenshot image files are partially determined by the
    %   ArtifactsRootFolder property on the TestRunner used to run any tests
    %   containing ScreenshotDiagnostic instances. If ScreenshotDiagnostic
    %   instances are used outside of a test run or diagnosed manually using
    %   the diagnose method, the location is equal to tempdir().
    %
    %   ScreenshotDiagnostic methods:
    %       ScreenshotDiagnostic - Class constructor
    %
    %   ScreenshotDiagnostic properties:
    %       Prefix - Character vector prepended to the name of the screenshot image file
    %
    %   Examples:
    %
    %       % Create a test file that uses the ScreenshotDiagnostic
    %       classdef testFeature < matlab.unittest.TestCase
    %           methods(Test)
    %               function testFailureExample(testCase)
    %                   import matlab.unittest.diagnostics.ScreenshotDiagnostic;
    %                   % Provide a ScreenshotDiagnostic as a Test Diagnostic
    %                   testCase.verifyTrue(false, ... % fail for demonstration purposes
    %                       ScreenshotDiagnostic);
    %               end
    %
    %               function testLogExample(testCase)
    %                   import matlab.unittest.diagnostics.ScreenshotDiagnostic;
    %                   import matlab.unittest.Verbosity;
    %                   % Provide a ScreenshotDiagnostic with a custom prefix as a Logged Diagnostic
    %                   testCase.log(Verbosity.Terse, ... % log for demonstration purposes
    %                       ScreenshotDiagnostic('Prefix','LoggedScreenshot_'));
    %               end
    %           end
    %       end
    %
    %       % Create a runner with a specified artifacts root folder
    %       runner = matlab.unittest.TestRunner.withTextOutput;
    %       exampleArtifactsRootFolder = fullfile(pwd,'MyTestArtifacts');
    %       mkdir(exampleArtifactsRootFolder);
    %       runner.ArtifactsRootFolder = exampleArtifactsRootFolder;
    %
    %       % Run the test file with the runner
    %       suite = testsuite('testFeature.m');
    %       runner.run(suite);
    %
    %   See also:
    %       tempdir
    %       matlab.unittest.TestRunner/ArtifactsRootFolder
    %       matlab.unittest.diagnostics.Diagnostic
    %       matlab.unittest.diagnostics.FileArtifact

    %  Copyright 2016-2024 The MathWorks, Inc.
    methods
        function diag = ScreenshotDiagnostic(varargin)
            % ScreenshotDiagnostic - Class constructor
            %
            %   ScreenshotDiagnostic() creates a new ScreenshotDiagnostic instance.
            %   When diagnosed, the instance captures all screens where each captured
            %   screenshot image file is named [prefix uniqueIdentifier '.png'] where
            %   prefix is 'Screenshot_' by default and uniqueIdentifier is an
            %   automatically generated unique identifier. The location of each
            %   screenshot image file can be viewed within the character vector set on
            %   the DiagnosticText property or can be programmatically accessed by the
            %   FileArtifact instance set on the Artifacts property.
            %
            %   ScreenshotDiagnostic('Prefix',prefix) creates a new
            %   ScreenshotDiagnostic instance that captures all screens where each
            %   captured screenshot image file is given a name that begins with the
            %   prefix provided. prefix can be given as a string scalar or character
            %   vector. If not provided, the default value for 'Prefix' is
            %   'Screenshot_'.
            %
            %   See also:
            %       matlab.unittest.diagnostics.Diagnostic/Artifacts
            %       matlab.unittest.diagnostics.Diagnostic/DiagnosticText
            %       matlab.unittest.diagnostics.FileArtifact
            defaultPrefix = 'Screenshot_';
            diag = diag@matlab.unittest.internal.mixin.PrefixMixin(defaultPrefix);
            diag.parse(varargin{:});

            validatePrefixInAGeneratedPathname(diag.Prefix);
        end
    end

    methods(Hidden)
        function diagnoseWith(diag,diagData)
            import matlab.unittest.Verbosity;
            import matlab.unittest.diagnostics.FileArtifact;
            import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;
            import matlab.lang.internal.uuid;
            a_uuid = uuid;
            fileName = diag.Prefix + a_uuid + ".png";
            

            files = captureScreens(char(diagData.ArtifactsStorageFolder),fileName);
            if isscalar(files)
                msgId = 'MATLAB:unittest:ScreenshotDiagnostic:ScreenshotCaptured';
            else
                msgId = 'MATLAB:unittest:ScreenshotDiagnostic:ScreenshotsCaptured';
            end
          
            fileList = arrayfun(@(file) createFileLink(file,diagData),files);
            fileListText = join(fileList,newline);

            diag.Artifacts = arrayfun(@(f)FileArtifact(f, FinalLocation=diagData.ArtifactsDisplayFolder),files);
            
            if diagData.Verbosity == Verbosity.None
                diag.DiagnosticText = '';
            else
                diag.DiagnosticText = sprintf('%s\n%s',...
                    getString(message(msgId)),fileListText);
            end
        end

        function bool = producesSameResultFor(~,diagData1,diagData2)
            bool = diagData1.ArtifactsStorageFolder == diagData2.ArtifactsStorageFolder && ...
                ~xor(diagData1.Verbosity,diagData2.Verbosity) && ...
                 diagData1.ArtifactsDisplayFolder == diagData2.ArtifactsDisplayFolder;
        end
    end
end


function cmdText = createCommandThatOpensImage(finalArtifactFileName)
cmdText = sprintf('web(''%s'',''-new'');',strrep(finalArtifactFileName,"'","''"));
end


function files = captureScreens(folder,fileName)
if ismac()
    [files,success] = captureScreensOnMacOS(folder,fileName);
    if success
        return;
    end
end

%Use pf screencapture for Windows and Linux. 
files = captureScreensUsingPF(folder,fileName);
end


function [files,success] = captureScreensOnMacOS(folder,fileName)
numScreens = size(get(groot,'MonitorPositions'),1);
if numScreens == 1
    files = fullfile(folder,fileName);
else
    [~,file,ext] = fileparts(fileName);
    files = arrayfun(@(k) fullfile(...
        folder,strcat(sprintf("%s_%u",file,k),ext)), 1:numScreens);
end
[system_status, ~] = system(sprintf('/usr/sbin/screencapture %s', ...
    char(join("""" + files + """"))));
success = system_status==0;
end


function file = captureScreensUsingPF(folder,fileName)
import matlab.ui.internal.hasDisplay;

if isunix && ~hasDisplay
    error(message('MATLAB:unittest:ScreenshotDiagnostic:ScreenshotNotCaptured'));
end

if ~isfolder(folder)
    [status, msg, msgID] = mkdir(folder);
    
    if ~status
        error(msgID, msg);
    end
end

file = fullfile(folder,fileName);
matlab.unittest.internal.screencapture(char(file));
end

function validatePrefixInAGeneratedPathname(prefix)
import matlab.lang.internal.uuid;
import matlab.unittest.internal.validateGeneratedPathname;
validateGeneratedPathname(prefix + uuid + ".png",'Prefix');
end

function fileLink = createFileLink(file,diagData)
import matlab.unittest.internal.diagnostics.CommandHyperlinkableString;

displayText = diagData.createDisplayFileName(file);
fileLink = indentWithArrow(CommandHyperlinkableString(...
    displayText, createCommandThatOpensImage(displayText)));
end
