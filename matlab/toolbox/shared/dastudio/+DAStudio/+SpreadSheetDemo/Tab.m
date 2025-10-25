classdef Tab < handle
    %TAB Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tabTitle;
        tabName;
        tabDesc;
    end
    
    methods
        function this = Tab(title, name, description)
           this.tabTitle = title;
           this.tabName = name;
           this.tabDesc  = description;
        end
    end
end

