%% DeepSinse
%% ========================================================================
%% networkValidatorAddFn
%% Code for validating the DeepSinse neural network
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function [accuracy,FPR] = networkValidatorAddFn(neuralNet,imageVec,trueClassVec)

%% calculating accuracy
netClassVec = classify(neuralNet,imageVec);
accuracy = sum(netClassVec == categorical(trueClassVec))/numel(categorical(trueClassVec));
FP = 0;
for particleId = 1 : length(netClassVec)
    if(netClassVec(particleId) == '1' && categorical(trueClassVec(particleId)) == '0')
        FP = FP + 1;
    end
end
P = sum(netClassVec == '0');
FPR = FP / P;