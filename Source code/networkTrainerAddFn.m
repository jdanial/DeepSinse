%% DeepSinse
%% ========================================================================
%% networkTrainerAddFn
%% Code for training the DeepSinse neural network
%% ========================================================================
%% Copyright 2020 John S H Danial
%% Department of Chemistry, Univerity of Cambridge

function neuralNet = networkTrainerAddFn(roiRadius,imageVec,classVec)

%% designing neuralNetwork architecture
imageSize = [(2 * roiRadius) + 1 (2 * roiRadius) + 1 1];
layers = [    
imageInputLayer(imageSize)
convolution2dLayer([(2 * roiRadius) (2 * roiRadius)],200)
fullyConnectedLayer(2)
softmaxLayer
classificationLayer];

%% training options
opts = trainingOptions('sgdm', ...
    'ExecutionEnvironment','cpu',...
    'InitialLearnRate',0.001,...
    'MaxEpochs',1,...
    'Shuffle','once', ...
    'Plots','training-progress',...
    'MiniBatchSize',10,...
    'Verbose',false);

%% training neuralNetwork
neuralNet = trainNetwork(imageVec,categorical(classVec),layers,opts);

%% saving neuralNetwork
save(['neuralNetwork.mat'],'neuralNet');
end