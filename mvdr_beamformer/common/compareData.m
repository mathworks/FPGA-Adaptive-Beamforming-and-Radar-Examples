function err_vec = compareData(reference,actual,figure_number,textstring)

% Vector input only
if ~isvector(reference) || ~isvector(actual)
    error('Input signals must be vector');
else
    if isrow(reference)
        reference = transpose(reference);
    end
    if isrow(actual)
        actual = transpose(actual);
    end
end

% Make signals same length if necessary
if length(reference) ~= length(actual)
    warning(['Length of reference (%d) is not the same as actual signal (%d).'...
        ' Truncating the longer input.'],length(reference),length(actual));
    len = 1:min(length(reference),length(actual));
    reference = reference(len);
    actual = actual(len);
end

% Turn complex into vector
if xor(isreal(reference),isreal(actual))
    error('Input signals are not both real or both complex');
elseif ~isreal(reference)
    ref_vec = double([real(reference) imag(reference)]);
    act_vec = double([real(actual) imag(actual)]);
    tag = {'(Real)','(Imag)'};
    cmplx = 1;
else
    ref_vec = double(reference);
    act_vec = double(actual);
    tag = {''};
    cmplx = 0;
end

% Configure figure
if iscell(figure_number)
    if size(figure_number,2) == 3
        figure(figure_number{3});
    else
        figure(1); % for backward compatability 
    end
else
    figure(figure_number);
end
c = get(groot,'defaultAxesColorOrder');

% Compute error
err_vec = ref_vec - act_vec;
max_err = max(abs(err_vec));
max_ref = max(abs(ref_vec));
fprintf('\nMaximum error for %s out of %d values\n',textstring,length(actual));

% 4 layouts:
% fig = #, signal = real: subplot(111)
% fig = #, signal = cmplx: subplot(211) & (212)
% fig = {X,Y}, signal = real: subplot(X1Y)
% fig = {X,Y}, signal = cmplx: subplot(X,1,Y*2-1) & (X,2,Y*2)

for n = 1:size(ref_vec,2)
    fprintf('%s %d (absolute), %d (percentage)\n',tag{n},max_err(n),max_err(n)/max_ref(n)*100);
    if isnumeric(figure_number)
        row_num = size(ref_vec,2);
        col_num = 1;
        plot_num = n;
    else
        row_num = figure_number{1};
        col_num = size(ref_vec,2);
        plot_num = figure_number{2};
        if cmplx 
            plot_num = (figure_number{2}-1)*2+n;
        end
    end
    subplot(row_num,col_num,plot_num);
    plot(ref_vec(:,n),'Color',c(3,:));
    hold on
    plot(act_vec(:,n),'Color',c(1,:));
    plot(err_vec(:,n),'Color',c(2,:));
    legend('Reference','Actual','Error')
    hold off
    title(sprintf('%s %s\n max error = %.3d',textstring,tag{n},max_err(n)));
end
end
