%%%% model symulacyjny kompresji danych %%%%
%% inicjalizacja parametr�w
close all
clc
clear all
format short% eng
% parametry sta�e
TEST_DATA_BITWIDTH = 16; % szeroko�� bitowa pr�bek testowych (sign int)
TEST_VECTOR_LENGTH = 32; % ilo�� pr�bek w wektorze danych testowych
% parametry testowane 
blockSize = 1; % rozmiar blok�w danych do skalowania
Qs = 16; % szeroko�� bitowa wsp�czynika skalowania
Qq = 16; % szeroko�� bitowa kwantyzacji
% Zmienne pomocnocze zale�ne od testowanych parametr�w
NUM_OF_BLOCKS = TEST_VECTOR_LENGTH/blockSize;

%% inicjalizacja wektora danych testowych
testData = randi([-(2^(TEST_DATA_BITWIDTH-1)) (2^(TEST_DATA_BITWIDTH-1))],1,TEST_VECTOR_LENGTH); % wektor losowych integer�w nie wiekszych ni� 2^TEST_DATA_BITWIDTH
%testData = (rand(1,TEST_VECTOR_LENGTH)-0.5).*(2^TEST_DATA_BITWIDTH-1); %wektor losowych danych o warto�ci nie wi�kszej ni� 2^TEST_DATA_BITWIDTH
%testData = linspace(1,(2^TEST_DATA_BITWIDTH-1),TEST_VECTOR_LENGTH); % wektor warto�ci stale rosnacych
numOfReadSamples = 1;
readBlock = zeros(NUM_OF_BLOCKS,blockSize);

%% podzia� na bloki
% disp('-------')
% disp('dzielenie na bloki')
% disp('-------')
for currentBlock = 1:(NUM_OF_BLOCKS)
    while numOfReadSamples <= blockSize
        readBlock(currentBlock,numOfReadSamples) = testData((currentBlock-1)*blockSize + numOfReadSamples);
        numOfReadSamples = numOfReadSamples + 1;
    end
    %disp(readBlock(currentBlock,:));
    numOfReadSamples = 1;
end

%% skalowanie
% disp('-------')
% disp('skalowanie')
% disp('-------')
scaledBlockData = zeros(NUM_OF_BLOCKS,blockSize);
maxSample = 0;
scalingFactor = ones(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:(NUM_OF_BLOCKS)
    % maxSample - A(k), pr�bka o najwi�kszej warto�ci bezwzgl�dnej w bloku
    maxSample = max(abs(readBlock(currentBlock,:)));
    % scalingFactor - S(k), scaling factor ograniczony przez szeroko�� bitow� podczas wysy�ania
    %scalar = ((2^Qs)-1)/maxSample;
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
    if ceil(maxSample) > ((2^Qs)-1)
        scalingFactor(currentBlock) = ((2^Qs)-1);
    else
        scalingFactor(currentBlock) = ceil(maxSample);
    end
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nPrzeskalowane dane:\n',currentBlock,scalingFactor(currentBlock));
    %scaledBlockData(currentBlock,1:blockSize) = (testData(1+(currentBlock-1)*blockSize:(currentBlock*blockSize)).*((2^Qq)-1))./scalingFactor(currentBlock);
    scaledBlockData(currentBlock,:) = readBlock(currentBlock,:).*(2^(Qq-1)-1)./scalingFactor(currentBlock);
    %disp(scaledBlockData(currentBlock,:));
end

%% kwantyzacja
%quant = QUANTIZER('Roundmode',round,'Overflowmode',saturate,'Format',[wordlength exponentlength]);
%quantizedBlockData = scaledBlockData;
quantizedBlockData = zeros(NUM_OF_BLOCKS,blockSize);
quantizationIndexes = zeros(NUM_OF_BLOCKS,blockSize);
quantizationPoints = -(2^(Qq-1)):(2^(Qq-1));
for currentBlock = 1:(NUM_OF_BLOCKS)
    quantizationIndexes(currentBlock,:) = quantiz(scaledBlockData(currentBlock,:),quantizationPoints);
    %sample=1;
    for j=quantizationIndexes(currentBlock)
        quantizedBlockData(currentBlock,:)=quantizationPoints(j+1);
        %sample = sample + 1;
    end
    fprintf('Quantized data for block %d:\n',currentBlock);
    disp(quantizedBlockData(currentBlock,:));
end

%% odtwarzanie danych
% disp('-------')
% disp('odtwarzanie')
% disp('-------')
rescaledBlockData = zeros(NUM_OF_BLOCKS,blockSize);
for currentBlock = 1:(NUM_OF_BLOCKS)
    %scalar = ((2^Qs)-1)/max(abs(readBlock(currentBlock,:)));
%     fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nOdtworzone dane:\n',currentBlock,scalingFactor(currentBlock));
    rescaledBlockData(currentBlock,1:blockSize) = (quantizedBlockData(currentBlock,:).*scalingFactor(currentBlock))./((2^(Qq-1))-1);
    %disp(rescaledBlockData(currentBlock,:));
end

%% por�wnanie danych �r�d�owych i odtworzonych
disp('-------')
disp('EVM')
disp('-------')
EVM = ones(1,NUM_OF_BLOCKS);
for currentBlock = 1:(NUM_OF_BLOCKS)
    EVM(currentBlock) = sqrt( sum( (readBlock(currentBlock,:)-rescaledBlockData(currentBlock,:)).^2 )/sum( readBlock(currentBlock,:).^2 ) )*100;
end
disp(EVM)
disp('Mean EVM')
disp(mean(EVM))
% disp('-------')
% disp('koniec')
% disp('-------')