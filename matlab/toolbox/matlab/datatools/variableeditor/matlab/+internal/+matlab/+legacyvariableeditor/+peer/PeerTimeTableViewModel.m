classdef PeerTimeTableViewModel < internal.matlab.legacyvariableeditor.peer.PeerTableViewModel & internal.matlab.legacyvariableeditor.TimeTableViewModel
    %PeerTimeTableViewModel Peer TimeTable View Model (Inherits from
    %PeerTable as well as TimeTable views)

    % Copyright 2013-2018 The MathWorks, Inc.
    methods
        function this = PeerTimeTableViewModel(parentNode, variable, viewID, usercontext)
            if nargin < 3 
                usercontext = '';
                viewID = '';
            elseif nargin < 4
                usercontext = '';
            end
            this@internal.matlab.legacyvariableeditor.TimeTableViewModel(variable.DataModel, viewID);
            this = this@internal.matlab.legacyvariableeditor.peer.PeerTableViewModel(parentNode,variable, viewID, usercontext);            
            this.setColumnModelProperty(1,'backgroundColor','#F5F5F5');
            this.setTableModelProperty('ShowColumnHeaderNumbers', false);
        end
    end  
end
