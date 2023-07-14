function varargout = sim_with_progress(model)
    % Opens and runs a Simulink model from MATLAB. During simulation dots, ".",
    % are displayed in the MATLAB command window indicating simulation progress.
    % Each dot represents 10% of the simulation.
    
    open_system(model);
    [~,name,ext] = fileparts(which(model));
    disp(['Running ' name ext]);
    
    stopTime = evalin('base',get_param(model,'StopTime'));
    
    % Stop and delete timer if it's still running.    
    t = timerfind('name','simProgress');
    if ~isempty(t)
        stop(t);
        delete(t);
    end

    l_showProgress(0,true);
    
    % Create and start timer.
    t               = timer('name','simProgress');
    t.Period        = 0.2;
    t.ExecutionMode = 'fixedRate';
    t.TimerFcn      = @(myTimerObj,thisEvent)l_showProgress(get_param(model,'SimulationTime')/stopTime);
    start(t);
    
    % Run Simulink model.
    try
        if nargout > 0
            simout = sim(model);
            varargout{1} = simout;
        else
            sim(model);
            % assign logged signals to base workspace
            vars = whos;
            for ii=1:numel(vars)
                var = vars(ii);
                if ~any(strcmp(var.name,{'t','stopTime','model','name','ext'}))
                    assignin('base',var.name,eval(var.name));
                end
            end
        end
        l_showProgress(1);
    catch me
        % Stop and delete timer.
        stop(t); delete(t);
        throw(me);
    end
    
    stop(t); delete(t);
    
    fprintf(newline);
    
end

function l_assignVarsInBase()

end

function l_showProgress(progress, initialize)
	if nargin < 2
		initialize = false;
	end
	
	length = 30;
	returnStr = char(8*ones(1,length+11,'uint8'));
	
	if initialize
		prefix = char([]);
	else
		% Clear previous line
		prefix=returnStr;
	end
	progmark = round(length*progress);
	pct = progress*100;
	pct_int = floor(pct);
	pct_frac = round(100*(pct-pct_int));
	if pct_frac>=100
		pct_frac=0;
	end
	str = [prefix '[' repmat('■',1,progmark) repmat('-',1,length-progmark) '] ' sprintf('%3d',pct_int) '.' sprintf('%02d',pct_frac) '%%' newline];
	fprintf(str);
end
