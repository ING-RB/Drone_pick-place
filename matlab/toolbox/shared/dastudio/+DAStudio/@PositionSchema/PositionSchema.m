classdef PositionSchema < matlab.mixin.SetGet & matlab.mixin.Copyable
%DAStudio.PositionSchema class
%    DAStudio.PositionSchema properties:
%       showPort - Property is of type 'bool'  
%       portSide - Property is of type 'PortSide enumeration: {'Left','Right'}'  
%       name - Property is of type 'string'  
%       originPosVector - Property is of type 'string'  
%       units - Property is of type 'Units enumeration: {'km','m','cm','mm','mi','ft','in'}'  
%       origin - Property is of type 'Space enumeration: {'WORLD','ADJOINING'}'  
%       axes - Property is of type 'Space enumeration: {'WORLD','ADJOINING'}'  


properties (SetObservable)
    %SHOWPORT Property is of type 'bool' 
    showPort (1, 1) logical = false;
    %PORTSIDE Property is of type 'PortSide enumeration: {'Left','Right'}' 
    portSide DAStudio.Enums.PortSide = DAStudio.Enums.PortSide.Left;
    %NAME Property is of type 'string' 
    name char = '';
    %ORIGINPOSVECTOR Property is of type 'string' 
    originPosVector char = '';
    %UNITS Property is of type 'Units enumeration: {'km','m','cm','mm','mi','ft','in'}' 
    units DAStudio.Enums.Units = DAStudio.Enums.Units.km;
    %ORIGIN Property is of type 'Space enumeration: {'WORLD','ADJOINING'}' 
    origin DAStudio.Enums.Space = DAStudio.Enums.Space.WORLD;
    %AXES Property is of type 'Space enumeration: {'WORLD','ADJOINING'}' 
    axes DAStudio.Enums.Space = DAStudio.Enums.Space.WORLD;
end


    methods  % constructor block
        function this = PositionSchema()
            this.showPort = false;
            this.portSide = DAStudio.Enums.PortSide.Left;
            this.name = 'CG';
            this.originPosVector = '[1 -1 0]';
            this.units = DAStudio.Enums.Units.m;   
        end  % PositionSchema
        
    end  % constructor block

    methods 
    end   % set and get functions
    
end  % classdef

