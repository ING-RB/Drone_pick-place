classdef (Sealed) ToolstripForm < ...
        matlabshared.transportapp.internal.utilities.forms.BaseForm
    %TOOLSTRIPFORM class contains the names and additional input argument
    %values of all the toolstrip section View and Controller classes, like
    %the WriteSectionView and WriteSectionController for the write section.

    % Copyright 2020-2022 The MathWorks, Inc.

    %% View and Controller Properties
    properties
       %% WRITE SECTION
       WriteSectionView (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.write.View")

       WriteSectionController (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.write.Controller")

       %% READ SECTION
       ReadSectionView (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.read.View")

       ReadSectionController (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.read.Controller")

       % Show the Flush Button in the toolstrip read section.
       % ShowFlushButton = true (default) - Flush button appears in the
       %                                    read section of the toolstrip.
       % ShowFlushButton = false - Flush button does not appear in the read
       %                           section of the toolstrip.
       ShowFlushButton (1,1) logical = true

       %% ANALYZE SECTION
       AnalyzeSectionView (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.analyze.View")

       AnalyzeSectionController (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.analyze.Controller")

       %% COMMUNICATION LOG SECTION
       CommunicationLogSectionView (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.communicationlog.View")

       CommunicationLogSectionController (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.communicationlog.Controller")

       %% EXPORT SECTION
       ExportSectionView (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.export.View")

       ExportSectionController (1,1) matlabshared.transportapp.internal.utilities.forms.Entries = ...
           matlabshared.transportapp.internal.utilities.forms.Entries("matlabshared.transportapp.internal.toolstrip.export.Controller")
    end
end
