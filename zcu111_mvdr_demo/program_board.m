% program_board Utility script to program the board after bitstream generation

% Create a ZynqRF connection object
z=zynqrf;

% Program the board
z.ProgramRFSoC('ModelName','TxSteering_RxMVDR_4x4_HDL_IQ');

% Wait for first reboot
fprintf('Waiting for reboot...');
pause(5);
timercount = 0;
while timercount<120
    [s,~] = system(sprintf('ping -n 1 %s',z.IPAddress));
    if (s)
       timercount = timercount+2;
       pause(2);
       fprintf('.');
    else
        break
    end
end
fprintf('\n');

% Refresh connection
z.checkConnection();
pause(5);

% Generate overlay for 32-bit stream channel data
dts_ovly_dst = ZynqRF.ZCU111.common.utils.dtoGenerate(32,false);

% Upload to target
foldername = '/tmp/hdlcoder_rd';
z.execute(sprintf('mkdir %s',foldername));
z.putFile(dts_ovly_dst,foldername);       

% Apply overlay
fprintf('Applying devicetree overlay...\n');
dtbo_target = strcat(foldername,'/mw_overlay.dtbo');
dts_target = strcat(foldername,'/mw_overlay.dts');
dtbo_convert_cmd = sprintf('dtc -o dtb -o %s -@ %s',dtbo_target,dts_target);
dtbo_apply_cmd = sprintf('fw_setdtoverlay %s',dtbo_target);
z.execute(dtbo_convert_cmd);
[~,resultStr_dto] = z.execute(dtbo_apply_cmd);

% Reboot again to apply changes
fprintf('Rebooting...\n');
z.execute('reboot');