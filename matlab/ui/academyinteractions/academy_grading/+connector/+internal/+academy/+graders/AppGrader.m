classdef AppGrader < connector.internal.academy.graders.Grader
    %APPGRADER grades app interactions. Does not contain any app specific code
    % simply creates a file for the test and runs it. Reports results as a
    % true/false.
    
    properties (Access=private)                   
        results
        syntaxErrorFlag
        
        runner
        graderPlugin
        diagnosticsPlugin
        
        warningState
        autogenerateHint = false;
    end
    
    methods (Static)        
        function result = gradeSubmission(testFolder)
            grader = connector.internal.academy.graders.AppGrader(testFolder);
            grade(grader);
            result = getResultsInJson(grader);
            resetWarningState(grader);
        end
    end
    
    methods
        
        function obj = AppGrader(testFolder)
            import connector.internal.academy.graders.*;

            obj.warningState = warning;
            warning('off');
            
            obj.testFolder       = testFolder;
            obj.autogenerateHint = false;      
            obj.syntaxErrorFlag  = false;
            
            warning('off');     
            
            obj.runner = matlab.unittest.TestRunner.withNoPlugins;
            obj.graderPlugin = connector.internal.academy.plugins.GraderPlugin('', '');
            obj.diagnosticsPlugin = connector.internal.academy.plugins.DiagnosticsPlugin;
            obj.runner.addPlugin(obj.graderPlugin);
            obj.runner.addPlugin(obj.diagnosticsPlugin);            
        end
                
        function resultStr = getResultsInJson(obj)
            o = struct;
            %Ensure results and assessments are arrays in the JSON
            o.tests = num2cell(obj.results);
            for i = 1:numel(o.tests)
                o.tests{i}.assessments = num2cell(o.tests{i}.assessments);
            end
            o.correct         = obj.getCorrectness;
            o.hint            = obj.results(1).hint;
            o.submissionCode  = '';  
            o.syntaxErrorFlag = obj.syntaxErrorFlag;
            resultStr         = obj.getTrimmedResultString(mls.internal.toJSON(o));
        end
        
        function resetWarningState(obj)
           warning(obj.warningState);
        end
        
        function grade(obj)                        
            testFiles = dir([obj.testFolder filesep 'test_exercise_*']);
            obj.results = obj.createEmptyResultsStruct;
            for i = 1:numel(testFiles)
                obj.results(i) = obj.runExercise(fullfile(obj.testFolder, testFiles(i).name));
            end 
            
            obj.setCorrectness(all([obj.results.correct]));          
        end        
    end
    
    methods (Access=private)
        
        %There is a certain maximum size of output that can be sent from
        %the worker to the client. MO says it's 44000, and the command
        %window will only display 25000 in traditional MATLAB. Our output
        %string typically only inflates this big if there is a large amount
        %of command window output. To reduce the size, we don't want to
        %just truncate the string, as that would result in invalid JSON.
        %Instead, we truncate just the command window output from the
        %exercises here. This requires a bit of back and forth conversions
        %to get the character sizes right, since JSON strings are typically
        %longer than MATLAB strings due to the escape characters (\n, \t,
        %etc.)
        function trimmedResultStr = getTrimmedResultString(obj,resultStr)   
            trimmedResultStr = resultStr;
            numChars = numel(trimmedResultStr);
            delta = numChars - obj.MAX_JSON_RESULTS_SIZE;
            if (delta > 0)
                o = mls.internal.fromJSON(trimmedResultStr);
                for i = 1:numel(o.tests)
                    stringBefore = mls.internal.toJSON(o.tests(i).codeOutput);
                    sizeBefore = numel(stringBefore);
                    stringAfter = ['"' stringBefore((1+delta):(end-1)) '"'];
                    o.tests(i).codeOutput = mls.internal.fromJSON(stringAfter);
                    sizeAfter = numel(stringAfter);
                    change = sizeBefore - sizeAfter;
                    delta = delta - change;
                    if (delta <= 0)
                        break;
                    end
                end
                %Ensure results and assessments are arrays in the JSON
                o.tests = num2cell(o.tests);
                for i = 1:numel(o.tests)
                    o.tests{i}.assessments = num2cell(o.tests{i}.assessments);
                end
                trimmedResultStr = mls.internal.toJSON(o);
            end
        end
        
        function s = createEmptyResultsStruct(~)
            s = struct('assessments',[],'hint','','diagnostics',[],...
                'runTimeErrorFlag',[],'errorObject',[],'errorMessage',[],...
                'correct',[],'codeOutput','','exerciseCode','');
        end
        
        function s = createEmptyAssessmentStruct(~)
            s = struct('Name',[],'Passed',[],'Failed',[],...
                'Incomplete',[],'Duration',[],'ScriptCode','','Diagnostics','');
        end
        
        function [testResults,t] = runTestsInProperContext(obj,tests)
            %Generally, the unit test framework does a nice job of
            %isolating the code from other workspace variables. However,
            %many other things in MATLAB (figures, random number seed,
            %etc.) are more "global". Here, we try to emulate true
            %isolation by resetting each of those items before we
            %run the test.
            tic;
            rng(0);
            close all;
            fclose all;
            resetWarningState(obj);               
            testResults = obj.runner.run(tests);
            warning('off');               
            t = toc;
        end
        
        function results = runExercise(obj,testFile)            
            results = obj.createEmptyResultsStruct;
            [~,testFileName] = fileparts(testFile);
            
            testModel = connector.internal.academy.testmodels.CodyTestScriptModel.fromString(fileread(testFile), testFileName);
            tests = matlab.unittest.Test.fromProvider(connector.internal.academy.providers.AcademyScriptTestCaseProvider(testModel,false));
            [testResults,testDuration] = obj.runTestsInProperContext(tests);
            diagnosticResults = obj.diagnosticsPlugin.Details;
            
            assessmentStruct = obj.createEmptyAssessmentStruct;
            for i = 1:numel(testResults)
                assessmentStruct(i).Name = testResults(i).Name;
                assessmentStruct(i).Passed = testResults(i).Passed;
                assessmentStruct(i).Failed = testResults(i).Failed;
                assessmentStruct(i).Incomplete = testResults(i).Incomplete;
                assessmentStruct(i).Duration = testResults(i).Duration;
                assessmentStruct(i).ScriptCode = diagnosticResults(i).ScriptCode;
                assessmentStruct(i).Diagnostics = strtrim(diagnosticResults(i).Diagnostics);
            end            
            
            results.assessments = assessmentStruct;
            results.runTimeErrorFlag = ((numel(obj.graderPlugin.exceptionObject.stack) > 0)...
                || (~strcmp(obj.graderPlugin.exceptionObject.message,''))) || (obj.syntaxErrorFlag);          
            results.correct = all([testResults.Passed]);
            results.codeOutput = obj.graderPlugin.codeOutput;
            results.exerciseCode = testModel.ImplicitCellContent;
            
            results.codeOutput = strrep(results.codeOutput,char(8),'');
            
            if results.runTimeErrorFlag || obj.syntaxErrorFlag                    
                results.errorObject = obj.graderPlugin.exceptionObject;                
                if (numel(results.errorObject.stack) > 0)
                    results.errorMessage = results.errorObject.getReport;
                else
                    results.errorMessage = results.errorObject.message;
                end
            end
            
            if results.correct
                results.hint = 'Correct';
            else
                results.hint = 'Incorrect';
            end
        end
    end
end