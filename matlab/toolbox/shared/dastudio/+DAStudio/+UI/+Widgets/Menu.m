classdef Menu < DAStudio.UI.Core.BaseObject    
    properties
        MenuItems = [];
    end    
     methods             
        function this = Menu()
           this.Type = 'Menu';
        end
        function addSeparator(obj)
            menuSeparator = DAStudio.UI.Widgets.MenuItem;
            menuSeparator.name = 'separator';
            obj.MenuItems = [obj.MenuItems menuSeparator];
        end
        function addMenuItem(obj, menuitem)
            obj.MenuItems = [obj.MenuItems menuitem];
        end
     end
end