classdef MEViewDomain < handle & matlab.mixin.SetGet & matlab.mixin.Copyable
%DAStudio.MEViewDomain class
%    DAStudio.MEViewDomain properties:
%       Name - Property is of type 'string'  
%       ActiveView - Property is of type 'handle'  
%       ViewManager - Property is of type 'handle'  
%       ActiveViewReason - Property is of type 'ustring'  
%
%    DAStudio.MEViewDomain methods:
%       getActiveView -  Get active view for the domain.
%       getFactoryView -  Get factory view for the domain.
%       setActiveView -  Set active view for the domain.


properties (SetObservable)
    %NAME Property is of type 'string' 
    Name char = '';
    %ACTIVEVIEW Property is of type 'handle' 
    ActiveView 
    %VIEWMANAGER Property is of type 'handle' 
    ViewManager 
    %ACTIVEVIEWREASON Property is of type 'ustring' 
    ActiveViewReason char = '';
end


    methods  % constructor block
        function this = MEViewDomain(manager, name)
        % Manages Domains for view management.

        % Name of this domain.
        this.Name = name;
        % Manager managing this domain.
        this.ViewManager = manager;
        % Current view for this domain.
        this.ActiveView = [];
        end  % MEViewDomain
        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function [view reason] = getActiveView(this)
           % Get active view for the domain.
    
           view = this.ActiveView;
           % Get factory view if there is not active view yet.
           if isempty(view) || ~isvalid(view)
               % Return factory's version. This could be empty.
               view = this.getFactoryView();
               this.ActiveView = view;
               if ~isempty(view)
                   this.ActiveViewReason = DAStudio.message('modelexplorer:DAS:ReasonDefault');
               end
           end
           reason = this.ActiveViewReason;     
       end  % getActiveView
       
        %----------------------------------------
       function view = getFactoryView(this)
           % Get factory view for the domain.
    
           % Returning empty view is fine as per specs and in that case there
           % won't be any suggestion until and unless user makes explicit change
           % in the view for an active domain.
           
           % Return factory view for the given domain.
           % Factory Suggestions and Domains map.
           fSuggestions = {   'Simulink', 'Block Data Types'; ...
                              'Stateflow', 'Stateflow'; ...
                              'Workspace', 'Data Objects'; ...
                              'DataDictionary', 'Dictionary Objects'; ...
                              'FunctionDeclarations', 'Functions'; ...
                              'DataDictionary_Other', 'Dictionary Other Data'; ...
                              'Configurations', 'Configurations';...
                             };
                         
           % Default
           viewName = 'Default';
           % if ~isempty(find(ismember(fSuggestions(:,1), this.Name) == 1))
           if any(ismember(fSuggestions(:,1), this.Name) == 1)
               % viewName = char(fSuggestions(ismember(fSuggestions(:,1), this.Name) == 1, 2));
               viewName = char(fSuggestions(ismember(fSuggestions(:,1), this.Name) == 1, 2));
           end
           
           view = findobj(this.ViewManager, '-isa', 'DAStudio.MEView', 'Name', viewName);
           if isa(view, 'DAStudio.MEViewManager') % why is viewmanager returned?
               view = [];
           end
       end  % getFactoryView
       
        %----------------------------------------
       function setActiveView(this, view)
           % Set active view for the domain.
           this.ActiveView = view;
           if ~isempty(view)
               this.ActiveViewReason = DAStudio.message('modelexplorer:DAS:ReasonRecentlyUsed');
           end
       end  % setActiveView
       
end  % public methods 

end  % classdef

