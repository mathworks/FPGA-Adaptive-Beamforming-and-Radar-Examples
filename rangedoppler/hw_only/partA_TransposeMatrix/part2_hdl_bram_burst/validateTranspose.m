dataOut = out.logsout.find('axi4mrd_dataOut').Values.Data;
dataValid = out.logsout.find('axi4mrd_validOut').Values.Data;
% validLength = sum(dataValid == 1) - mod(length(dataValid),N1*N2);
% matrixExtract = dataOut(dataValid(1:validLength));
% numMatrices = length(matrixExtract)/(N1*N2);
matrixExtract = dataOut(dataValid);
trimLen = mod(length(matrixExtract),N1*N2);
matrixExtract = matrixExtract(1:(length(matrixExtract) - trimLen));
c = reshape(matrixExtract,N2,N1,[]); %<--- note we swap N2 and N1 because this is transposed..

numMatrices = length(matrixExtract)/(N1*N2);
for ii = 1:numMatrices
    diff = double(MatrixInput.') - double(c(:,:,ii));
    if ~any(diff(:)~=0)
        fprintf('transpose good = %d \n',ii);
    else
        warning('bad transpose!')
    end
end