classdef (Abstract) TestCase < matlab.uitest.internal.AppLockingTestCase & ...
                               matlab.uitest.internal.GestureProvider 
    %TESTCASE - TestCase for writing tests using the App Testing Framework
    %
    %   Use the matlab.uitest.TestCase class to write tests that exercise
    %   the functionality of MATLAB Apps and leverage the App Testing
    %   Framework. The matlab.uitest.TestCase class inherits functionality
    %   from the matlab.unittest.TestCase class.
    %
    %   To avoid user interference with the App under test, new uifigure
    %   instances are "locked" automatically. The contents of locked
    %   figures are unresponsive to human interactions but continue to
    %   react to the programmatic gestures of the TestCase.
    %
    %   matlab.uitest.TestCase methods:
    %     forInteractiveUse  -    Create a TestCase for interactive use
    %     press              -    Press UI component within App
    %     hover              -    Hover UI component within App
    %     choose             -    Choose UI component or option within App
    %     drag               -    Drag UI component within App
    %     scroll             -    Scroll on UI component within App
    %     type               -    Type in UI component within App
    %     chooseContextMenu  -    Choose context menu item in UI component 
    %                             within App
    %     dismissAlertDialog -    Dismiss topmost alert dialog box within App
    %
    %   Example:
    %
    %     % Create a class-based MATLAB unit test that derives from
    %     % matlab.uitest.TestCase:
    %     classdef MyUITest < matlab.uitest.TestCase
    %         methods (Test)
    %             function testLampColorInteraction(testCase)
    %                 % Create an App and specify teardown routine
    %                 f = uifigure;
    %                 testCase.addTeardown(@delete, f);
    %
    %                 % Configure a red-colored lamp to change to green
    %                 % when a button is pressed
    %                 lamp = uilamp(f, 'Position', [50 100 20 20], 'Color', 'red');
    %                 button = uibutton(f, ...
    %                     'ButtonPushedFcn', @(o,e)set(lamp, 'Color', 'green'));
    %
    %                 % Exercise - press the button to invoke its ButtonPushedFcn
    %                 testCase.press(button);
    %
    %                 % Verify that the lamp color is green
    %                 testCase.verifyEqual(lamp.Color, [0 1 0], ...
    %                     'The lamp should be green');
    %             end
    %         end
    %     end
    %
    %     % Run the test
    %     >> runtests MyUITest
    %
    % See also matlab.unittest.TestCase.
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    methods (Static)
        function testCase = forInteractiveUse(varargin)
            %FORINTERACTIVEUSE - Create a TestCase to use interactively
            %
            %   TESTCASE = matlab.uitest.TestCase.forInteractiveUse creates
            %   a TestCase instance for experimentation at the MATLAB
            %   command prompt. TESTCASE is a matlab.uitest.TestCase
            %   instance that reacts to qualification failures and
            %   successes by printing messages to standard output (the
            %   screen).
            %
            %   Examples:
            %
            %     % Configure a red-colored lamp to change to green when a button is pressed
            %     f = uifigure;
            %     lamp = uilamp(f, 'Position', [50 100 20 20], 'Color', 'red');
            %     button = uibutton(f, ...
            %         'ButtonPushedFcn', @(o,e)set(lamp, 'Color', 'green'));
            %
            %     % Create a TestCase for interactive use at the MATLAB Command Prompt
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     % Exercise - press the button to invoke its ButtonPushedFcn
            %     testCase.press(button);
            %
            %     % Produce a failing verification
            %     testCase.verifyEqual(lamp.Color, 'green');
            %
            %     % Produce a passing verification
            %     testCase.verifyEqual(lamp.Color, [0 1 0]);
            
            import matlab.uitest.InteractiveTestCase;
            import matlab.unittest.internal.addInteractiveListeners;
            testCase = InteractiveTestCase;
            addInteractiveListeners(testCase, varargin{:});
        end
    end
end
