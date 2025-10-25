function sysObjMap = hdlsysobjs
% map from System object to HDL implementation

%   Copyright 2011-2024 The MathWorks, Inc.

% This file is eval'ed, not executed. Do not count this for code coverage. Do
% not place an 'end' at the end of this file.
sysObjMap = containers.Map;

% mapping for new hdl.RAM which replaces hdlram
sysObjMap('hdl.RAM') = 'hdldefaults.RamSystem';
sysObjMap('hdl.MatrixMultiply') = 'hdldefaults.MatrixMultiplyStream';
sysObjMap('hdl.MatrixInverse') = 'hdldefaults.MatrixInverseStream';

sysObjMap('hdl.internal.PIRHDLFunctionObject') = 'hdldefaults.Cordic';

sysObjMap('hdl.Delay') = 'hdldefaults.IntegerDelay';
sysObjMap('hdl.TappedDelay') = 'hdldefaults.TappedDelay';

% system objects used in in IP core wrapper
sysObjMap('hdl.internal.ArbiterRequestCreator') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.ArbiterRequestMonitor') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.BlastTracker') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.CountLimitedCounter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.CountRegisterFIFO4') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.FIFOPointers') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.FIFORAM') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.FreeRunningCounter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.InFlightTracker') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.JustCountFIFO4') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.ModuloCounter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.OneHotSwitch') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.ReadArbiter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.ReadArbiterSwitch') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.ReadInterfaceFIFO4') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.RegisterFIFO4') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.RequestCounter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.RequestSerializer') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.SendRequestsManager') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.SimplifiedReadAdapter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.SimplifiedWriteAdapter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.SkidFIFO') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.SwitchArbiterRequestMonitor') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.WrCompleteTracker') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.WriteArbiter') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.WriteArbiterSwitch') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.WriteInterfaceFIFO4') = 'ALWAYS_ALLOW';
sysObjMap('hdl.internal.WriteRequestCreator') = 'ALWAYS_ALLOW';


% end

% LocalWords:  eval'ed hdlram hdldefaults PIRHDL
