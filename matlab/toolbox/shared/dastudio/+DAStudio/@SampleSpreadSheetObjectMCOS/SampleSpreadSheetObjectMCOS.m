classdef SampleSpreadSheetObjectMCOS < handle
    properties
        mProp1;        
        mProp2;
        mProp3;        
    end
    methods
        function this = SampleSpreadSheetObjectMCOS(name, value, type)
            this.mProp1 = name;           
            this.mProp2 = value;
            this.mProp3 = type;            
        end
        function label = getDisplayLabel(obj)
            label = obj.mProp1;
        end
        %
        function fileName = getDisplayIcon(~)
            fileName = 'toolbox/shared/dastudio/resources/info.png';        
        end
        %
        function propValue = getPropValue(obj, propName)
            switch propName       
                case 'Prop1'
                    propValue = obj.mProp1;        
                case 'Prop2'
                    propValue = obj.mProp2;
                case 'Prop3'
                    propValue = obj.mProp3;           
                otherwise
                    propValue = 'NA';     
            end
        end
        %
        function menu = getContextMenu(obj)
            menu = DAStudio.UI.Widgets.Menu;
            menuItem1 = DAStudio.UI.Widgets.MenuItem;
            menuItem1.name = 'Menu Item1';
            menuItem1.accel = 'Ctrl+1';
            menuItem1.icon = 'toolbox/shared/dastudio/resources/info.png';
            menuItem1.callback = 'pwd';
            menu.addMenuItem(menuItem1);
            menuItem2 = DAStudio.UI.Widgets.MenuItem;
            menuItem2.name = 'Menu Item2';
            menuItem2.accel = 'Ctrl+2';
            menuItem2.icon = 'toolbox/shared/dastudio/resources/info.png';
            menuItem2.callback = 'ls';
            menu.addMenuItem(menuItem2);
        end
        %
        function isHyperlink = propertyHyperlink(~, propName, clicked)            
            isHyperlink = false;
            if strcmp(propName, 'Prop3')
                isHyperlink = true;
            end
            if clicked
                % do something in response to click on the hyperlink
            end
        end
        %
        function isValid = isValidProperty(~, propName)            
            isValid = false;
            switch propName       
                case 'Prop1'
                    isValid = true;        
                case 'Prop2'
                    isValid = true;
                case 'Prop3'
                    isValid = true;           
                otherwise
                    isValid = false;     
            end
        end
    end
end
