%%%% model symulacyjny kompresji danych
%% inicjalizacja parametr�w
close all
clc
clear all
format short eng

TEST_DATA_SIZE = 1024; % rozmiar wektora danych testowych
BLOCK_SIZE = 16; % rozmiar blok�w danych do skalowania
Qs = 16; % szeroko�� bitowa wsp�czynika skalowania
Qq = 12; % szeroko�� bitowa kwantyzacji
%% inicjalizacja wektora danych
testData = randi([-(2^(Qs-1)) (2^(Qs-1))],1,TEST_DATA_SIZE);
%testData = (rand(1,TEST_DATA_SIZE)-0.5).*(2^Qs-1); % wektor losowych danych o warto�ci nie wi�kszej ni� najwi�ksza pr�bka IQ
%testData = linspace(1,(2^Qs-1),TEST_DATA_SIZE); % wektor warto�ci stale rosnacych
numOfReadSamples = 1;
readBlock = zeros(TEST_DATA_SIZE/BLOCK_SIZE,BLOCK_SIZE);
%% podzia� na bloki
disp('dzielenie na bloki')
disp('-------')
for i = 1:(TEST_DATA_SIZE/BLOCK_SIZE)
    while numOfReadSamples <= BLOCK_SIZE
        readBlock(i,numOfReadSamples) = testData((i-1)*BLOCK_SIZE + numOfReadSamples);
        numOfReadSamples = numOfReadSamples + 1;
    end
    disp(readBlock(i,:));
    numOfReadSamples = 1;
end
%% skalowanie
disp('-------')
disp('skalowanie')
disp('-------')
scaledBlockData = zeros(TEST_DATA_SIZE/BLOCK_SIZE,BLOCK_SIZE);
maxSample = 0;
scalingFactor = ones(TEST_DATA_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_DATA_SIZE/BLOCK_SIZE)
    % maxSample - A(k), pr�bka o najwi�kszej warto�ci bezwzgl�dnej w bloku
    maxSample = max(abs(readBlock(i,:)));
    % scalingFactor - S(k), scaling factor ograniczony przez szeroko�� bitow� podczas wysy�ania
    %scalar = ((2^Qs)-1)/maxSample;
    %scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
    if ceil(maxSample) > ((2^Qs)-1)
        scalingFactor(i) = ((2^Qs)-1);
    else
        scalingFactor(i) = ceil(maxSample);
    end
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nPrzeskalowane dane:\n',i,scalingFactor);
    scaledBlockData(i,1:BLOCK_SIZE) = (testData(1+(i-1)*BLOCK_SIZE:(i*BLOCK_SIZE)).*((2^Qq)-1))./scalingFactor(i);
    disp(scaledBlockData(i,:));
end
%% kwantyzacja
%quant = QUANTIZER('Roundmode',round,'Overflowmode',saturate,'Format',[wordlength exponentlength]);
quantizedBlockData = zeros(TEST_DATA_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_DATA_SIZE/BLOCK_SIZE)
    quantizedBlockData(i) = quantiz(scaledBlockData(i),linspace(-(2^(Qq-1)),(2^(Qq-1)),2^Qq));
end
%% odtwarzanie danych
disp('-------')
disp('odtwarzanie')
disp('-------')
rescaledBlockData = zeros(TEST_DATA_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_DATA_SIZE/BLOCK_SIZE)
    %scalar = ((2^Qs)-1)/max(abs(readBlock(i,:)));
    fprintf('Blok %d, Wsp�lczynnik skalowania: %d\nOdtworzone dane:\n',i,scalingFactor(i));
    rescaledBlockData(i,1:BLOCK_SIZE) = (quantizedBlockData(i,:).*scalingFactor(i))./((2^Qq)-1);
    disp(rescaledBlockData(i,:));
end
%% por�wnanie danych �r�d�owych i odtworzonych
disp('-------')
disp('EVM')
disp('-------')
EVM = (((readBlock-rescaledBlockData).^2)./(readBlock.^2))*100;
disp(EVM)
disp('Mean EVM')
disp(mean(mean(EVM)))
disp('-------')
disp('koniec')
disp('-------')