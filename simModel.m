%% model symulacyjny kompresji danych
close all
clc
clear all

TEST_VECTOR_SIZE = 32;
BLOCK_SIZE = 4;
Qs = 5;
Qq = 3;

testVector = [1:1:TEST_VECTOR_SIZE];
readSamples = 1;
readBlock = zeros(TEST_VECTOR_SIZE/BLOCK_SIZE,BLOCK_SIZE);
for i = 1:(TEST_VECTOR_SIZE/BLOCK_SIZE)
    while readSamples <= BLOCK_SIZE
        readBlock(i,readSamples) = testVector((i-1)*BLOCK_SIZE + readSamples);
        readSamples = readSamples + 1;
    end
    readSamples = 1;
end

for i = 1:(TEST_VECTOR_SIZE/BLOCK_SIZE)
    scalar = (2^(Qs))/max(abs(readBlock(i,:)))
    scaledVector = scalar./testVector
end