function S = saveobj(ds)
%saveobj   Custom saveobj for SpreadsheetDatastore to pin property order
%          during load.

    S = struct();

    S.PrivateNumHeaderLines        = ds.PrivateNumHeaderLines;
    S.PrivateReadVariableNames     = ds.PrivateReadVariableNames;
    S.PrivateVariableNames         = ds.PrivateVariableNames;
    S.PrivateVariableTypes         = ds.PrivateVariableTypes;
    S.PrivateSelectedVariableNames = ds.PrivateSelectedVariableNames;
    S.PrivateSelectedVariableTypes = ds.PrivateSelectedVariableTypes;
    S.PrivateReadSize              = ds.PrivateReadSize;
    S.PrivateSheetFormatInfo       = ds.PrivateSheetFormatInfo;
    S.ConstructionDone             = ds.ConstructionDone;
    S.RangeVector                  = ds.RangeVector;
    S.IsFirstFileBook              = ds.IsFirstFileBook;
    S.CurrInfo                     = ds.CurrInfo;
    S.CurrRangeVector              = ds.CurrRangeVector;
    S.SchemaVersion                = ds.SchemaVersion;
    S.TextType                     = ds.TextType;
    S.SelectedVariableNamesIdx     = ds.SelectedVariableNamesIdx;
    S.ReadFailureRule              = ds.ReadFailureRule;
    S.MaxFailures                  = ds.MaxFailures;
    S.PrivateReadFailuresList      = ds.PrivateReadFailuresList;
    S.TotalFiles                   = ds.TotalFiles;
    S.Splitter                     = ds.Splitter;
    S.Folders                      = ds.Folders;
    S.PreserveVariableNames        = ds.PreserveVariableNames;
    S.PrivateOutputType            = ds.OutputType;
    S.OutputTypeInitialized        = true;  % Overriden during loadobj.
    S.PrivateSheets                = ds.PrivateSheets;
    S.PrivateRange                 = ds.PrivateRange;
    S.SheetsToReadIdx              = ds.SheetsToReadIdx;
    S.IsDataAvailableToConvert     = ds.IsDataAvailableToConvert;
    S.NumRowsAvailableInSheet      = ds.NumRowsAvailableInSheet;
    S.PrivateMaxFailures           = ds.PrivateMaxFailures;
    S.PrivateReadFailureRule       = ds.PrivateReadFailureRule;
    S.PrivateReadCounter           = ds.PrivateReadCounter;
    S.PreviewCall                  = ds.PreviewCall;
    S.ErrorSplitIdx                = ds.ErrorSplitIdx;
    S.RecalculateFolders           = ds.RecalculateFolders;
    S.CreatedOnPC                  = ds.CreatedOnPC;
    S.MultipleFileSeps             = ds.MultipleFileSeps;
    S.BackSlashIndices             = ds.BackSlashIndices;
    S.SetFromLoadObj               = ds.SetFromLoadObj;
    S.AlternateFileSystemRoots     = ds.AlternateFileSystemRoots;
    S.TimeVariableIndex            = ds.TimeVariableIndex;
end
