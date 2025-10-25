classdef ResultDetails
    % ResultDetails -  Class for modifying test result details
    %
    %   The ResultDetails class allows a TestRunnerPlugin instance to
    %   modify the Details property of TestResult objects.
    %
    %   ResultDetails methods:
    %       append - append data to Details on TestResult object
    %
    %   See Also
    %       matlab.unittest.plugins.TestRunnerPlugin
    %       matlab.unittest.TestResult
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(Hidden,SetAccess=immutable,GetAccess=protected)
        DistributeLoop
        TestRunData
        DetailsLocationProvider
    end
    
    methods(Hidden, Access = {?matlab.unittest.internal.plugins.plugindata.TestResultDetailsAccessorMixin,...
            ?matlab.unittest.plugins.plugindata.ResultDetails})
        function resultDetails = ResultDetails(testRunData,locationProvider,distributeLoop)
            resultDetails.TestRunData = testRunData;
            resultDetails.DetailsLocationProvider = locationProvider;
            resultDetails.DistributeLoop = distributeLoop;
        end
    end
    
    methods
        function append(resultDetails,fieldName, data)
            % APPEND - add data to list of test result details
            %
            % APPEND(RESULTDETAILS,FIELDNAME,DATA) appends DATA to a field
            % of the Details property of TestResult objects, specified as
            % FIELDNAME. If FIELDNAME does not exist, the method adds it to
            % the Details structure.
            import matlab.unittest.internal.plugins.TestResultDetailsAppendTask;
            
            validateFieldName(fieldName);
            resultDetails.TestRunData.Buffer.insert(...
                TestResultDetailsAppendTask(resultDetails.TestRunData, fieldName, data,...
                resultDetails.DetailsLocationProvider, resultDetails.DistributeLoop));
        end
    end
    
    methods(Hidden)
        function replace(resultDetails,fieldName,data)
            import matlab.unittest.internal.plugins.TestResultDetailsReplaceTask;
            
            validateFieldName(fieldName);
            resultDetails.TestRunData.Buffer.insert(...
                TestResultDetailsReplaceTask(resultDetails.TestRunData, fieldName, data,...
                resultDetails.DetailsLocationProvider, resultDetails.DistributeLoop));
        end
    end
end
function validateFieldName(fieldName)
import matlab.unittest.internal.mustBeTextScalar;
import matlab.unittest.internal.mustContainCharacters;

mustBeTextScalar(fieldName,'FieldName');
mustContainCharacters(fieldName,'FieldName');
assert(isvarname(fieldName)|| iskeyword(fieldName),message('MATLAB:unittest:ResultDetails:FieldNameIsNotAValidVarname',fieldName));
end