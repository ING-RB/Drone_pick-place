classdef LineCreator < handle
%

%   Copyright 2015-2020 The MathWorks, Inc.

    properties(Constant,Hidden)
        Marker = {'.' '+' 'o' '*' 'x' 's' 'd' '^' 'v' '>' '<' 'p' 'h'};
        LineStyle = {'-' '--' '-.' ':'};
        NonTrellisStyle = {'Color','MarkerType','MarkerSize'};
    end
    
    properties (GetAccess='public',SetAccess='protected')
        XData
        YData
        GroupData
        AxesLocation
        NumRows
        NumColumns
    end
    
    properties (Access = public)
        Style
    end
    
    properties(Access = private)
        View
        GroupName_I
        NumGroupLevel   % number of group levels in each grouping variable
        NumGroup_I      % number of group levels in each shown grouping variable
        GroupIndex_I    % grpIdx for each gv
        GroupIndex_Show % grpIdx for each shown gv
        GroupLabels_I   % labels from group bins
        WrongGroup      % groups not existed in the data
    end
    
    properties(Hidden,GetAccess='public',SetAccess='private')
        X          % used for peripheral plot
        Y          % used for peripheral plot
        Trellis    % used for setting XLabels/YLabels
        GroupIndex % Group Index (nonTrellis Index) for each line
        NumGroup   % number of nonTrellis group, for GroupStyles repmat
        NumXAxisLevel
        NumYAxisLevel
        XAxisIndex
        YAxisIndex
        ShowGroupingVariableIndex
        GroupBins
        XDatetimeIndex
        YDatetimeIndex
        WrongBinFlag = 0    % whether all GroupBin elements do not exist.
        NanGroup            % contains data not belonging to any group bin
    end
    
    methods
        function this = LineCreator(input)
            this.View = input;
            this.updateGroup;
            this.updateGroupLabelsAndShowGroups;
            this.updateShowGroupingVariable;
            this.updateData;
            this.updateStyle;
        end
        
        updateGroup(this)
        
        updateGroupLabelsAndShowGroups(this)
        
        updateShowGroupingVariable(this)
        
        updateData(this)
        
        updateStyle(this)
        
    end
end
