function sfxfile(file, localfunction) %#ok<INUSD>
%

% Copyright 2014-2020 The MathWorks, Inc.

if ~license('test', 'Stateflow') 
    error(message("MATLAB:sfx:SFLicenseMissingForSFX"));
else
    cfg = Stateflow.App.Cdr.CdrConfMgr.getInstance;
    if ~exist('Stateflow.App.Cdr.CdrChart', 'class') || isequal(cfg.testingUnhandledErrors,'nosf')
        error(message("MATLAB:sfx:SFNotInstalledForSFX"));
    end
end
if exist(file , 'file')
    Stateflow.App.Studio.Open(file);
else
    yesTxt = getString(message("MATLAB:finishdlg:Yes"));
    button = '';
    s = settings;
    showNewFilePrompt = s.matlab.confirmationdialogs.EditorShowNewFilePrompt.ActiveValue;
    if showNewFilePrompt
        [~, name, ext] = fileparts(file);
        fileName = [name, ext];
        button = questdlg( ...
            getString(message("MATLAB:sfx:SFXOpenQuestDlgMsg", string(fileName))), ...
            getString(message("MATLAB:sfx:StateflowEditor")), ...
            yesTxt, ...
            getString(message("MATLAB:finishdlg:No")), ...
            yesTxt);
    end

    if ~showNewFilePrompt || strcmp(button, yesTxt)
        isFileNameValid = Stateflow.App.Studio.verifyUserFileName('', file);
        if ~isFileNameValid
            return;
        end
        chartH = Stateflow.App.Studio.New(file);
        if ~isempty(chartH)
            Stateflow.App.Studio.SaveAs(get_param(chartH.machine.name, 'handle'), file);
        end
    end
end

end

