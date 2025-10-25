classdef FigureCapability
% FIGURECAPABILITY
% This class is undocumented and may change.
    
    % Copyright 2024 The MathWorks, Inc.

    enumeration
        AppBuilding,
        DesktopDocument,
        DesignTime,
        Embedded,
        IsolatedRequested
    end
    
    properties (Constant)
    end

    methods (Static)

        function result = hasCapability(fig, capability)
            import matlab.ui.internal.FigureCapability;

            switch capability
              case FigureCapability.AppBuilding
                result = fig.IsAppBuilding;
              case FigureCapability.DesktopDocument
                result = fig.HasDesktopDocument;
              case FigureCapability.DesignTime
                result = fig.IsDesignTime;
              case FigureCapability.Embedded
                result = fig.IsEmbedded;
              case FigureCapability.IsolatedRequested
                result = fig.IsIsolatedRequested;
              otherwise
                result = false;
            end
        end

    end
    
end
