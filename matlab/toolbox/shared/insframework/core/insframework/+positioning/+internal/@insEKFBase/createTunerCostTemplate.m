function createTunerCostTemplate(filt)
%CREATETUNERCOSTTEMPLATE - create a cost function in the editor
%   Creates a cost function in the editor to be used as a custom cost
%   function when tuning an insEKF filter with the TUNE function. The
%   generated function computes the cost as the RMS error of the estimated
%   states vs the ground truth.
%
%   Example:
%   % Tune the insEKF with a custom cost function.
%
%   filt = insEKF;
%   createTunerCostTemplate(filt); % open new cost function in the editor
%   % Save the file in the editor as-is 
%   doc = matlab.desktop.editor.getActive;
%   doc.saveAs(fullfile(pwd, 'tunercost.m'));
%  
%   % Use this cost function to autotune.
%   % Load sensor data and ground truth
%   ld = load("accelGyroINSEKFData.mat");
%       
%   stateparts(filt, "Orientation", compact(ld.initOrient));
%   statecovparts(filt, "Orientation", 1e-2);
%  
%   mnoise = tunernoise(filt);
%   cfg = tunerconfig(filt, MaxIterations=1, ...
%          ObjectiveLimit=1e-4, ...
%          Cost="custom", ...
%          CustomCostFcn = @tunercost);
%   tunedmn = tune(filt, mnoise, ld.sensorData, ...
%           ld.groundTruth, cfg);
%  
%   See also: insEKF/tune, insEKF/tunerCostFcnParam

%   Copyright 2021 The MathWorks, Inc.

writer = sigutils.internal.emission.MatlabFunctionGenerator;
writer.Name = 'tunercost';
writer.RCSRevisionAndDate = false;
writer.TimeStampInHeader = true;
writer.H1Line = 'Cost function for tuning insEKF';
writer.Help = {...
    'Example cost function for tuning the insEKF.', ...
    'This function calculates cost as the RMS error of state estimates.', ...
    ' '};
writer.InputArgs = {'params', 'sensorData', 'groundTruth'};
writer.OutputArgs = {'cost'};
addStrings = @(x)writeStrings(writer, x);
addCR = @()addCode(writer, ' '); % add a carriage return;

sdStr = "sensorData";
gtStr = "groundTruth";
paramStr = "params";

% create sensors s1,s2, s3, ...
N = numel(filt.Sensors);
sname = strings(1,N);

% Add sensors
addStrings('% Create sensor instances')
addStrings('% NOTE: Ensure that non-toolbox supplied sensors');
addStrings('%       are instantiated and configured correctly.')

for ii=1:N
    sname(ii) = genvarname('s', ['s' sname]);
    s = filt.Sensors{ii};
    ctor = toConstructor(s, sname(ii));
    addStrings(ctor); 
end
addCR();

% Create motion model
addStrings('% Create motion model')
addStrings('% NOTE: Ensure that non-toolbox supplied motion model');
addStrings('%       is instantiated and configured correctly.')
m = filt.MotionModel;
mmStr = "mm";
mctor = toConstructor(m, mmStr);
addStrings(mctor);
addCR();

% Create insOptions
addStrings('% Create filter options')
o = filt.Options;
optStr = "opt";
ostr = toConstructor(o, "opt");
addStrings(ostr);
addCR();

% Create insEKF and initialize
addStrings('% Create filter')
filtStr = "filt";
filtInputs = [sname, mmStr, optStr];
filtconst = filtStr + " = insEKF(" + ...
    strjoin(filtInputs, ", ")  + ");";
addStrings(filtconst);

addStrings(filtStr + ".State = " + paramStr + ".State;");
addStrings(filtStr + ".StateCovariance = " + paramStr + ".StateCovariance;");
addStrings(filtStr + ".AdditiveProcessNoise = " + paramStr + ".AdditiveProcessNoise;");
addCR();

% Fuse
addStrings('% Fuse sensorData')
addStrings("poseEst = estimateStates(" + ...
    filtStr + ", " + ...
    sdStr + ", " + ...
    paramStr + ");")
addCR();

% Convert Tables to Arrays
addStrings("% Convert any quaternions to arrays")
addStrings("gtConverted = convertvars(" + gtStr + ", @(x)isa(x, 'quaternion'), @compactQuaternions);");
addStrings("estConverted = convertvars(poseEst, @(x)isa(x, 'quaternion'), @compactQuaternions);");
addCR();

% Prune to same vars as groundTruth
addStrings("% Prune some columns")
addStrings("gtvars = gtConverted.Properties.VariableNames;");
addStrings("prunedEst = estConverted(:, gtvars);");
addCR();

% Convert to arrays
addStrings("% Tables now contain the same variables in the same order. Convert tables to arrays.")
addStrings("garr = table2array(timetable2table(gtConverted, 'ConvertRowTimes', false));");
addStrings("sarr = table2array(timetable2table(prunedEst, 'ConvertRowTimes', false));")
addCR();

% RMS
addStrings("% RMS difference between two multi-variable timeseries.");
addStrings("% Using the approach defined in:");
addStrings('%   Abbeel, Pieter, et al. "Discriminative Training of Kalman Filters." Robotics: Science and Systems I,');
addStrings('%     Robotics: Science and Systems Foundation, 2005.');

addStrings("d = (garr - sarr).';");
addStrings("cost = sqrt(mean(vecnorm(d).^2));");

% Add the compactQuaternion function
localfcn = createLocalFcnCompactQuaternions();
addLocalFunction(writer,localfcn);

% Put this in the editor
buff = getFileBuffer(writer);
indentCode(buff);
contents = char(buff);
editorDoc = matlab.desktop.editor.newDocument(contents);
editorDoc.Text = contents;
editorDoc.smartIndentContents;
editorDoc.goToLine(1);
end

function fcn = createLocalFcnCompactQuaternions
fcn = sigutils.internal.emission.MatlabFunctionGenerator;
fcn.RCSRevisionAndDate = false;
fcn.TimeStampInHeader = false;
fcn.Name = 'compactQuaternions';
fcn.H1Line = 'make quaternions positive and compact';
fcn.EndOfFileMarker = false;
fcn.InputArgs = {'x'};
fcn.OutputArgs = {'y'};

addStrings = @(x)writeStrings(fcn, x);

% Enclose the parts() call in an if-else check that x is a quaternion. In
% MATLAB this is not necessary because the convertvars won't dispatch
% non-quaternions here. But Codegen does not know that and doesn't know
% what parts() is if there are no quaternions in groundTruth, which
% causes a codegen error.
addStrings("if isa(x, 'quaternion')")
addStrings("isneg = parts(x) < 0;");
addStrings("x(isneg) = -x(isneg);");
addStrings("y = compact(x);")
addStrings("else");
addStrings("y = x;");
addStrings("end");
end

function writeStrings(writer, x)
if isa(x, 'string')
    for ii=1:numel(x)
        addCode(writer, char(x(ii)) );
    end
else
    addCode(writer, char(x));
end
end

function s = toConstructor(obj, varname)

p = properties(obj);
Np = numel(p);
s = strings(1,Np+1);

classname = class(obj);
s(1) = varname + " = " + classname  + ";";
mc = meta.class.fromName(classname);
mp = mc.PropertyList;


for ii=1:Np
    % Generate property setting code only if the property has public get
    % and set access and is not constant.
    ga = mp(ii).GetAccess;
    sa = mp(ii).SetAccess;
    isconst = mp(ii).Constant;
    if ischar(ga) && strcmp(ga, 'public') && ...
        ischar(sa) && strcmp(sa, 'public') && ~isconst

        thisprop = mp(ii).Name;
        val = obj.(thisprop);
        if isenum(val)
            v = "'" + string(val) + "'";
        elseif isa(val, 'quaternion')
            v = "quaternion([" + mat2str(compact(val)) + "])";
        else
            v = matlab.system.internal.toExpression(val);
        end
        s(ii+1) = varname + "." + thisprop + " = " + v  + ";"; 
    end
end
end
