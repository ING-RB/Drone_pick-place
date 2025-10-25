classdef MEViewProperty < matlab.mixin.SetGet & matlab.mixin.Copyable & DAStudio.AbstractTreeNode
%DAStudio.MEViewProperty class
%    DAStudio.MEViewProperty properties:
%       Name - Property is of type 'string'  
%       Width - Property is of type 'int'  
%       isVisible - Property is of type 'bool'  
%       isMatching - Property is of type 'bool'  
%       isReserved - Property is of type 'bool'  
%       isTransient - Property is of type 'bool'  


properties (SetObservable)
    %NAME Property is of type 'string' 
    Name char = '';
    %WIDTH Property is of type 'int' 
    Width int32 = -1;
    %ISVISIBLE Property is of type 'bool' 
    isVisible logical = true;
    %ISMATCHING Property is of type 'bool' 
    isMatching logical = false;
    %ISRESERVED Property is of type 'bool' 
    isReserved logical = false;
    %ISTRANSIENT Property is of type 'bool' 
    isTransient logical = false;
end


    methods  % constructor block
        function this = MEViewProperty(name, varargin)
            if nargin == 1
                this.Name = name;
            end
            if strcmpi(this.Name, 'Name')
                this.isReserved = true;
            end
        end  % MEViewProperty
    end  % constructor block

    methods 
    end   % set and get functions 
end  % classdef

