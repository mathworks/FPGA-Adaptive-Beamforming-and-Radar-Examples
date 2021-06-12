dataOut = out.logsout.find('axi4mrd_dataOut').Values.Data;
dataValid = out.logsout.find('axi4mrd_validOut').Values.Data;
numMatrices = length(matrixExtract)/(N1*N2);

c = reshape(matrixExtract,N1,N2,numMatrices);

for ii = 1:numMatrices
    if isequal(MatrixInput.',c(:,:,ii))
        fprintf('transpose good = %d \n',ii);
    else
        warning('bad transpose!')
    end
end