function program_board(varargin)
%program_board Utility function to program the board after bitstream generation
%
%  program_board() programs the board with the bitfile found in hdl_prj.
%
%  program_board('ParameterName', Value) can be used to specify additional parameters:
%   
%    'IPAddress'     - IP address of the board.
%    'VivadoPrjDir'  - Vivado project directory name. (ignored if BitfilePath is specified)
%    'BitfilePath'   - Path to bitfile. (relative or full)
%
%   Copyright 2021-2022 The MathWorks, Inc.

p = inputParser;
p.addOptional('IPAddress','');
p.addOptional('VivadoPrjDir',fullfile('hdl_prj','vivado_ip_prj'));
p.addOptional('BitfilePath',fullfile('prebuilt','zcu111_mvdr.bit'));
p.addOptional('DeviceTree','');
p.addOptional('WaitForReboot',false);
p.parse(varargin{:});
args = p.Results;

IPAddress = args.IPAddress;
VivadoPrjDir = args.VivadoPrjDir;
BitfilePath = args.BitfilePath;

% Search for the bitfile if none specified
if isempty(BitfilePath)
    files = dir(VivadoPrjDir);
    runsDir = '';
    for ii=1:length(files)
        if regexp(files(ii).name,'.+\.runs')
            runsDir = files(ii).name;
            break
        end
    end
    if isempty(runsDir)
        error('Could not find a .runs directory in %s.',VivadoPrjDir)
    end
    BitfileDirPath = fullfile(VivadoPrjDir,runsDir,'impl_1');
    BitfileDirContents = dir(BitfileDirPath);
    fileNames = {BitfileDirContents.name};
    matchIdx = cellfun(@(x) endsWith(x,'.bit'), fileNames);
    if ~any(matchIdx)
        error('Directory ''%s'' does not contain a .bit file.',BitfileDirPath)
    end
    validFiles = fileNames(matchIdx);
    BitfileName = validFiles{1}; % use first entry found
    BitfilePath = fullfile(BitfileDirPath,BitfileName);
else
    if ~isfile(BitfilePath)
        error('Invalid bitfile path.')
    end
end

% Create board connection object
h = ZynqRFSoC.common.internal.zynqrf;
if ~isempty(IPAddress)
    h.IPAddress = IPAddress;
end

% Copy RF_Init.cfg
BitfileDirPath = fileparts(BitfilePath);
cfgfilePath = fullfile(BitfileDirPath,'RF_Init.cfg');
cfgfilePathLocal = fullfile(pwd,'RF_Init.cfg');
if isfile(cfgfilePath)
    copyfile(cfgfilePath,cfgfilePathLocal);
end

% Program the board
devicetree = 'devicetree.dtb';
rdName = 'IQ ADC/DAC Interface';
hRDParams = struct();
hRDParams.MW_ADD_DDR4 = 'false';
hRDParams.MW_AXIS_DATA_WIDTH = '32';
[~, result]= ZynqRFSoC.common.internal.downloadBitstreamToRFSoC(h,BitfilePath,devicetree,'',rdName,hRDParams);
disp(result);

if isfile(cfgfilePathLocal)
    delete(cfgfilePathLocal);
end

end