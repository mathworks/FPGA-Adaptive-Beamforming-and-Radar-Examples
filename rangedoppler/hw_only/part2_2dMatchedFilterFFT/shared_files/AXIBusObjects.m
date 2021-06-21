function AXIBusObjects() 
% AXIBUSOBJECTS initializes a set of bus objects in the MATLAB base workspace 

% Bus object: BusAXIWriteCtrlM2S 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'wr_addr';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'uint32';
elems(1).SampleTime = -1;
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'wr_len';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'uint32';
elems(2).SampleTime = -1;
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

elems(3) = Simulink.BusElement;
elems(3).Name = 'wr_valid';
elems(3).Dimensions = 1;
elems(3).DimensionsMode = 'Fixed';
elems(3).DataType = 'boolean';
elems(3).SampleTime = -1;
elems(3).Complexity = 'real';
elems(3).Min = [];
elems(3).Max = [];
elems(3).DocUnits = '';
elems(3).Description = '';

BusAXIWriteCtrlM2S = Simulink.Bus;
BusAXIWriteCtrlM2S.HeaderFile = '';
BusAXIWriteCtrlM2S.Description = '';
BusAXIWriteCtrlM2S.DataScope = 'Auto';
BusAXIWriteCtrlM2S.Alignment = -1;
BusAXIWriteCtrlM2S.Elements = elems;
clear elems;
assignin('base','BusAXIWriteCtrlM2S', BusAXIWriteCtrlM2S);

% Bus object: BusAXIWriteCtrlS2M 
clear elems;
elems(1) = Simulink.BusElement;
elems(1).Name = 'wr_ready';
elems(1).Dimensions = 1;
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'boolean';
elems(1).SampleTime = -1;
elems(1).Complexity = 'real';
elems(1).Min = [];
elems(1).Max = [];
elems(1).DocUnits = '';
elems(1).Description = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'wr_complete';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'boolean';
elems(2).SampleTime = -1;
elems(2).Complexity = 'real';
elems(2).Min = [];
elems(2).Max = [];
elems(2).DocUnits = '';
elems(2).Description = '';

BusAXIWriteCtrlS2M = Simulink.Bus;
BusAXIWriteCtrlS2M.HeaderFile = '';
BusAXIWriteCtrlS2M.Description = '';
BusAXIWriteCtrlS2M.DataScope = 'Auto';
BusAXIWriteCtrlS2M.Alignment = -1;
BusAXIWriteCtrlS2M.Elements = elems;
clear elems;
assignin('base','BusAXIWriteCtrlS2M', BusAXIWriteCtrlS2M);
