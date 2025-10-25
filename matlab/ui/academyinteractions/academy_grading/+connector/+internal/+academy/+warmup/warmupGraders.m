function warmupGraders
%

%   Copyright 2019-2024 The MathWorks, Inc.

connector.internal.academy.i18n.FeedbackTemplates.language.setLanguage('en');
connector.internal.academy.graders.GraderUtils.createFoldersAndAddToPath;

p = fileparts(mfilename('fullpath'));
f = fullfile(p,'warmupLiveEditorSubmission.mlx');
p = fullfile(p,'warmup');

connector.internal.academy.graders.CommandLineGrader.gradeSubmission('x=6','x=5',p);
connector.internal.academy.graders.ScriptGrader.gradeSubmission(f,f,p);

connector.internal.academy.graders.GraderUtils.removeFoldersFromPath;
evalin('base','clear');

end
