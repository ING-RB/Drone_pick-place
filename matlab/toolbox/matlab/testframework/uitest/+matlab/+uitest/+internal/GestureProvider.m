classdef (Abstract, Hidden) GestureProvider < matlab.unittest.internal.mixin.Subscribable
    % This class is undocumented and subject to change in a future release
    
    %GestureProvider - Interface class to drive MATLAB Apps
    %
    % See also matlab.uitest.TestCase.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = private, Constant)
        Driver = matlab.ui.internal.Driver;
    end
    
    methods (Sealed)
        function press(testCase, H, varargin)
            %PRESS Press UI component in App
            %
            %   press(TESTCASE, H) performs a "press" gesture on the UI
            %   component H for components that support this gesture.
            %   Examples of components that support the "press" gesture
            %   include uibutton, uicheckbox, uiradiobutton, and uiswitch.
            %
            %   press(TESTCASE, H, LOCATION) specifies the location to
            %   press within the component H. For example, H can be a
            %   uiaxes and LOCATION a 1x2 or 1x3 axes coordinate.
            %
            %   For more information on supported UI components and syntaxes,
            %   see the reference page for matlab.uitest.TestCase/press.
            %
            %   Examples:
            %
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     button = uibutton;
            %     testCase.press(button);
            %
            %     ax = uiaxes;
            %     testCase.press(ax, [0.2 0.4]);
            %
            % See also matlab.uitest.TestCase/choose.
            
            narginchk(2, Inf);
            testCase.publishGesture("press", H, varargin{:});
            testCase.Driver.press(H, varargin{:});
        end

        function hover(testCase, H, varargin)
            %HOVER Hover UI component in App
            %
            %   hover(TESTCASE, H) performs a "hover" gesture on the UI
            %   component H for components that support this gesture.
            %   Examples of components that support the "hover" gesture
            %   include uifigure, uiaxes and axes.
            %
            %   hover(TESTCASE, H, LOCATION) specifies the location to
            %   hover within the component H.
            %
            %   For more information on supported UI components and syntaxes,
            %   see the reference page for matlab.uitest.TestCase/hover.
            %
            %   Examples:
            %
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     f = uifigure;
            %     testCase.hover(f, [100 200]);
            %
            %     uiax = uiaxes;
            %     testCase.hover(uiax, [0.2 0.4]);
            %
            % See also matlab.uitest.TestCase/press.
            
            narginchk(2, Inf);
            testCase.publishGesture("hover", H, varargin{:});
            testCase.Driver.hover(H, varargin{:});
        end

        function choose(testCase, H, varargin)
            %CHOOSE Choose UI component or option in App
            %
            %   choose(TESTCASE, H, OPTION) chooses the option OPTION
            %   within the UI component H for components that support this
            %   gesture. Examples of components that support the "choose"
            %   gesture include uicheckbox, uiswitch, and uilistbox. The
            %   data type of OPTION depends on the type of component under
            %   test.  For example, if H is a uiswitch, OPTION is a text or
            %   numeric value. But if H is a uicheckbox, OPTION is a
            %   logical value.
            %
            %   For more information on supported UI components and syntaxes,
            %   see the reference page for matlab.uitest.TestCase/choose.
            %
            %   Examples:
            %
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     % Choose an item on a discrete knob
            %     knob = uiknob('discrete');
            %     % choose by "Item"
            %     testCase.choose(knob, 'Medium');
            %     % choose by Item index
            %     testCase.choose(knob, 1);
            %
            %     % Choose multiple items in a listbox
            %     listbox = uilistbox('Multiselect', 'on');
            %     testCase.choose(listbox, 1:3);
            %
            %     % Choose a tab within a tabgroup
            %     fig = uifigure;
            %     group = uitabgroup(fig);
            %     tab1 = uitab(group, 'Title', 'Tab #1');
            %     tab2 = uitab(group, 'Title', 'Tab #2');
            %     % The following are equivalent:
            %     testCase.choose(group, "Tab #2");
            %     testCase.choose(group, 2);
            %     testCase.choose(tab2);
            %
            % See also matlab.uitest.TestCase/press.
            
            narginchk(2, Inf);
            testCase.publishGesture("choose", H, varargin{:});
            testCase.Driver.choose(H, varargin{:});
        end

        function drag(testCase, H, start, stop, varargin)
            %DRAG Drag UI component within App
            %
            %  drag(TESTCASE, H, START, STOP) performs a "drag" gesture on
            %  the UI component H from the specified START value to STOP.
            %  This interaction is supported for axes, uiaxes, uislider
            %  and continuous uiknob components.
            %
            %  Examples:
            %
            %    testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %    knob = uiknob;
            %    testCase.drag(knob, 10, 90);
            %
            %    slider = uislider;
            %    testCase.drag(slider, 80, 23);
            %
            %    ax = axes(uifigure);
            %    plot(ax, 1:10);
            %    testCase.drag(ax, [3 4], [7 4]);
            %
            % See also matlab.uitest.TestCase/press.
            
            narginchk(4, Inf);
            testCase.publishGesture("drag", H, start, stop, varargin{:});
            testCase.Driver.drag(H, start, stop, varargin{:});
        end

        function type(testCase, H, text, varargin)
            %TYPE Types in UI component within App
            %
            %   type(TESTCASE, H, VALUE) types VALUE into the UI component H
            %   for components that support this gesture. Examples of
            %   components that support the "type" gesture include
            %   uieditfield, and uitextarea. VALUE specified
            %   depends on the component H under test. For example, a
            %   standard uieditfield uses a text-based value, while a
            %   numeric editfield uses a numeric value.
            %
            %   For more information on supported UI components and syntaxes,
            %   see the reference page for matlab.uitest.TestCase/type.
            %
            %   Examples:
            %
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     % Type in an editfield
            %     editfield = uieditfield;
            %     testCase.type(editfield, 'Hello World!');
            %
            %     % Type in a numeric editfield
            %     numedit = uieditfield('numeric');
            %     testCase.type(numedit, 126.88);
            %
            %     % Type in an editable dropdown
            %     dropdown = uidropdown('Editable', 'on');
            %     testCase.type(dropdown, 'Custom Item');
            %
            % See also matlab.uitest.TestCase/choose.
            
            narginchk(3, Inf);
            testCase.publishGesture("type", H, text, varargin{:});
            testCase.Driver.type(H, text, varargin{:});
        end

        function chooseContextMenu(testCase, H, varargin)
            %CHOOSECONTEXTMENU Choose context menu item in UI component within App
            %
            %  chooseContextMenu(TESTCASE, H, MENUITEM) opens the context menu
            %  in the UI component under test H and chooses one of its menu items,
            %  specified as MENUITEM. MENUITEM is the handle to the uimenu
            %  component within the context menu.
            %
            %  chooseContextMenu(TESTCASE, H, MENUITEM, LOCATION) specifies
            %  the location to open the context menu in the component H.
            %
            %  Examples:
            %    f = uifigure;
            %    testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %    im = uiimage(f);
            %    im.ImageSource ='peppers.png';
            %
            %    cm = uicontextmenu(f);
            %    menuItem1 = uimenu(cm, 'Label', 'value1');
            %    menuItem2 = uimenu(cm, 'Label', 'value2');
            %    im.ContextMenu = cm;
            %
            %    % Choose menuItem1 by opening the context menu of uiimage
            %    testCase.chooseContextMenu(im, menuItem1);
            %
            %    % Choose menuItem2 by opening the context menu of the axes
            %    % at the coordinates [0.6 0.6]
            %    ax = axes(f);
            %    ax.ContextMenu = cm;
            %
            %    testCase.chooseContextMenu(ax, menuItem2, [0.6 0.6]);
            %
            % See also matlab.uitest.TestCase/choose.
            
            narginchk(3, Inf);
            testCase.publishGesture("chooseContextMenu", H, varargin{:});
            testCase.Driver.contextmenu(H, varargin{:});
        end

        function dismissAlertDialog(testCase, FIG, varargin)
            %DISMISSALERTDIALOG Dismiss topmost alert dialog box within App
            %
            %  dismissAlertDialog(TESTCASE, FIG) closes the topmost alert
            %  dialog box in the window of the specified figure FIG.
            %
            %  Examples:
            %
            %    testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %    f = uifigure;
            %
            %    % Create an alert dialog box   
            %    uialert(fig,'File not found','Invalid File')
            %   
            %    % Close the alert dialog box
            %    testCase.dismissAlertDialog(fig)
            %
            % dismissAlertDilog is not recommended. Use dismissDialog
            % instead.
            %
            % See also matlab.uitest.TestCase/choose.
            
            narginchk(2, Inf);
            testCase.publishGesture("dismissAlertDialog", FIG, varargin{:});
            testCase.Driver.dismissAlert(FIG, varargin{:});
        end

        function scroll(testCase, H, varargin)
            %SCROLL Scroll on UI component within App
            %
            %    scroll(TESTCASE,H,direction)
            %    performs a "scroll" gesture on the UI component H. 
            %    The method scrolls from the center of H in the specified direction.
            %    You can specify direction as "left" or "right" to scroll
            %    horizontally, or as "up" or "down" to scroll vertically.
            %    Components that support the "scroll" gesture include axes and UI axes.
            %
            %  Examples:
            %
            %    testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %    ax = axes(uifigure);
            %    plot(ax,1:10)
            %    testCase.scroll(ax,"up")
            %    testCase.scroll(ax,"down")
            %    testCase.scroll(ax,"left")
            %    testCase.scroll(ax,"right")
            %
            % See also matlab.uitest.TestCase/drag.

            narginchk(3, Inf);
            testCase.publishGesture("scroll", H, varargin{:});
            testCase.Driver.scroll(H, varargin{:});
        end

        function chooseDialog(testCase, dialogType, varargin)
            %CHOOSEDIALOG Click option button in dialog box
            %
            % chooseDialog(TESTCASE, DIALOGTYPE,FIG, optionIndex)
            % programmatically clicks the optionIndexth button of
            % the frontmost dialog box of type DIALOGTYPE in the specified
            % figure window
            %
            % chooseDialog(TESTCASE, DIALOGTYPE,FIG, createBlockingDialogFcn, optionIndex)
            % programmatically clicks the optionIndexth button of
            % the Blocking DIALOGTYPE dialog box created by createBlockingDialogFcn 
            % in the figure FIG
            %
            % chooseDialog(TESTCASE, DIALOGTYPE,FIG, optionText)
            % programmatically clicks the button with optionText
            % from the topmost DIALOGTYPE dialog box in the figure FIG
            %
            % chooseDialog(TESTCASE, DIALOGTYPE,FIG, createBlockingDialogFcn, optionText)
            % programmatically clicks the button with optionText
            % from the Blocking DIALOGTYPE dialog box created by createBlockingDialogFcn 
            % in the figure FIG
            %
            % Examples:
            %     f = uifigure;
            %     testCase = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     createDialog(f);
            %
            %     % Choose using button index
            %     testCase.chooseDialog('uiconfirm', f, 1);
            %
            %     createDialog(f);
            %
            %     % Choose using button text
            %     testCase.chooseDialog('uiconfirm', f, 'Save as new');
            %
            %     % Choose using button index for blocking dialog box
            %     testCase.chooseDialog('uiconfirm', f, ...
            %     @()createBlockingDialog(f), 1);
            %
            %     % Choose using button text for blocking dialog box
            %     testCase.chooseDialog('uiconfirm', f, ...
            %     @()createBlockingDialog(f), 'Overwrite');
            %
            %     function createDialog(fig)
            %         msg = "Saving these changes will overwrite previous changes.";
            %         title = "Confirm Save";
            %         uiconfirm(fig,msg,title, ...
            %         "Options",["Overwrite","Save as new","Cancel"], ...
            %         "DefaultOption",2,"CancelOption",3);
            %     end
            %
            %     function selection = createBlockingDialog(fig)
            %         msg = "Saving these changes will overwrite previous changes.";
            %         title = "Confirm Save";
            %         selection = uiconfirm(fig,msg,title, ...
            %         "Options",["Overwrite","Save as new","Cancel"], ...
            %         "DefaultOption",2,"CancelOption",3);
            %      end
            %
            % See also matlab.uitest.TestCase/dismissDialog.

            narginchk(4, Inf);

            if isa(varargin{1}, "matlab.ui.Figure")
                % Dialog with figure as parent can publish diagnostics on
                % client
                testCase.publishGesture("chooseDialog", varargin{:});
            end

            testCase.Driver.chooseDialog(dialogType, varargin{:});

        end
        
        function dismissDialog(testCase, dialogType, varargin)
            %DISMISSDIALOG Close the frontmost dialog box in figure window
            %
            % dismissDialog(TESTCASE, DIALOGTYPE, FIG) closes the topmost
            % DIALOGTYPE dialog box in the window of the specified figure FIG
            %
            % dismissDialog(TESTCASE, DIALOGTYPE,FIG,...
            % createBlockingDialogFcn) closed the dialog box created by
            % createBlockingDialogFcn in the window of the specified
            % figure FIG
            %
            % Examples:
            %
            %     f = uifigure;
            %     tc = matlab.uitest.TestCase.forInteractiveUse;
            %
            %     % Create an alert dialog
            %     uialert(f,"File not found.","Invalid File");
            %
            %     % Close the alert dialog
            %     tc.dismissDialog('uialert', f);
            %
            %     % Close blocking confirmation dialog
            %     tc.dismissDialog('uiconfirm', f,...
            %          @()createBlockingDialog(f));
            %
            %     function selection = createBlockingDialog(fig)
            %         msg = "Saving these changes will overwrite previous changes.";
            %         title = "Confirm Save";
            %         selection = uiconfirm(fig,msg,title, ...
            %         "Options",["Overwrite","Save as new","Cancel"], ...
            %         "DefaultOption",2,"CancelOption",3);
            %      end
            %
            % See also matlab.uitest.TestCase/chooseDialog.
            
            narginchk(3, Inf);
            
            if isa(varargin{1}, "matlab.ui.Figure")
                % Dialog with figure as parent can publish diagnostics on
                % client
                testCase.publishGesture("chooseDialog", varargin{:});
            end
            
            testCase.Driver.dismissDialog(dialogType, varargin{:});

        end
    end
    
    methods(Sealed, Hidden)
        function doublepress(testCase, H, varargin)
            %DOUBLEPRESS Double-press UI component within App
            %
            %  doublepress(TESTCASE, H, LOCATION) performs a "double-press"
            %  gesture on the UI component H by double-clicking at the
            %  specified LOCATION within the component. The "double-press"
            %  gesture is supported for table UI components.
            %
            %  Examples:
            %    f = uifigure; 
            %    testCase = matlab.uitest.TestCase.forInteractiveUse;
            %    
            %    t = uitable(f, 'Data', magic(4),'CellDoubleClickedFcn',...
            %    @(o,e)disp(e));
            %
            %    % Double-press table cell [2 2]
            %    testCase.doublepress(t, [2 2])
            %
            % See also matlab.uitest.TestCase/choose.
            narginchk(2, Inf);
            testCase.publishGesture("doublepress", H, varargin{:});
            testCase.Driver.doublepress(H, varargin{:});
        end
    end

    methods (Access=private)
        function publishGesture(testCase, gesture, H, varargin)
            gestureData = struct("Gesture",gesture, "Handle",H, "Arguments",{varargin});
            testCase.publish("MATLAB:uitest:GestureDiagnostic", gestureData);
        end
    end
end

% LocalWords:  Subscribable uicheckbox uiradiobutton uiswitch uiaxes uiax uilistbox uiknob
% LocalWords:  Multiselect tabgroup uislider uieditfield uitextarea editfield numedit dropdown
% LocalWords:  uidropdown CHOOSECONTEXTMENU MENUITEM uiimage DISMISSALERTDIALOG uialert doublepress
