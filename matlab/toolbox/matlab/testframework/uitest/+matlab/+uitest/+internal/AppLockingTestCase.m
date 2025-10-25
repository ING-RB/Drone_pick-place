classdef (Abstract, Hidden) AppLockingTestCase < matlab.unittest.TestCase
    % This class is undocumented and subject to change in a future release
    
    %TESTCASE - TestCase Interface class for App (uifigure) locking 
    %
    %   To avoid user interference with the App under test, new uifigure
    %   instances are "locked" automatically. The contents of locked
    %   figures are unresponsive to human interactions but continue to
    %   react to the programmatic gestures of the TestCase.
    %
    % See also matlab.uitest.TestCase.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (Access = private, Constant)
        Driver = matlab.ui.internal.Driver;
    end
    
    methods (Sealed, TestClassSetup, Hidden)
        
        function lockNewFigures(testCase)
            
            import matlab.uiautomation.internal.FigureHelper;
            L = FigureHelper.setupLockListeners(testCase.Driver);
            testCase.addTeardown(@delete, L);
        end
        
    end
end

