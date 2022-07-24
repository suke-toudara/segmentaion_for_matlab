clc, close all, clear all;

%出現するクラス名
classes = [
    "boudle"
    "stem"
    "pillow"
    "back_ground"
    ];


%%



%テストデータ読み込み
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train');
imdsTrain = imageDatastore(imgDir);
%イメージの表示
%I = readimage(imdsTrain,5);
%I = histeq(I);
%imshow(I)

labelIDs = PixelLabelIDs();
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train_label');
pxdsTrain = pixelLabelDatastore(imgDir,classes,labelIDs);
tbl = countEachLabel(pxdsTrain);


%学習データ作成
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train');
imdsVal = imageDatastore(imgDir);


%学習用ラベルデータ作成
labelIDs = PixelLabelIDs(); %クラスに対応するRGBカラーを指定
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train_label');
pxdsVal = pixelLabelDatastore(imgDir,classes,labelIDs);

%disp(classes)
classes = pxdsTrain.ClassNames;
%disp(classes)

% Create pixel label datastores for training and test.
trainingLabels = pxdsTrain.Files();
valLabels = pxdsVal.Files();


pxdsTrain = pixelLabelDatastore(trainingLabels, classes, labelIDs); 
pxdsVal=pixelLabelDatastore(valLabels, classes, labelIDs); 
%%

% ネットワークの作成
%入力データサイズの統一
%imageSize = [720 960 3];
imageSize = [540 960 3];
numClasses = numel(classes);
%DeepLab v3+.モデルの作成
lgraph = deeplabv3plusLayers(imageSize, numClasses, "resnet18");
%クラスの重み付けを使用したクラスのバランス調整
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;
%クラスの重みを指定
pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);
%%
dsVal = combine(imdsVal,pxdsVal); %元画像と正解画像をセットにする





% 学習オプションの設定
%https://jp.mathworks.com/help/deeplearning/ref/trainingoptions.html(参考)
%{
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'ValidationData',dsVal,...
    'MaxEpochs',120, ...  
    'MiniBatchSize',4, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'Plots','training-progress',...
    'ValidationPatience', 10);
%}
options = trainingOptions('adam', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',10,...
    'LearnRateDropFactor',0.3,...
    'GradientDecayFactor',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'ValidationData',dsVal,...
    'MaxEpochs',120, ...  
    'MiniBatchSize',4, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'Plots','training-progress',...
    'ValidationPatience', 15);

%'ValidationPatience'は指定した回数損失値が減少しないと学習を強制終了する。

%%
%うまく動いていない
%データ拡張
dsTrain = combine(imdsTrain, pxdsTrain); %データを組み合わせる
xTrans = [-10 10];
yTrans = [-10 10];
dsTrain = transform(dsTrain, @(data)augmentImageAndLabel(data,xTrans,yTrans));

%imageAugmenter = imageDataAugmenter( ...
   % 'RandXReflection', true, ...
  %  'RandXScale',[1,2], ...
 %   'RandYReflection', true, ...
%dsTrain = augmentedImageDatastore(imageSize,dsTrain,'DataAugmentation',imageAugmenter);
%dsTrain=transform(dsTrain,@(x) imresize(x,imageSize));
%%
%disp(dsTrain)
%学習の開始
doTraining = true;
if doTraining    
    [net, info] = trainNetwork(dsTrain,lgraph,options);
else
    data = load('deeplabv3plusResnet18CamVid.mat'); 
    net = data.net;
end

save('trainedNetwork.mat', 'net');


%%
function labelIDs = PixelLabelIDs()
labelIDs = { ...
    
    % "boudle"
    [
    000 128 000; ... 
    ]
    
    % "stem" 
    [
    128 000 000; ... 
    ]

    % "pillow"
    [
    128 128 000; ... 
    ]
    
    %　"back_ground"
    [
    000 000 000;
    ]
    };
end



%%
function data = augmentImageAndLabel(data, xTrans, yTrans)
% Augment images and pixel label images using random reflection and
% translation.

for i = 1:size(data,1)
    
    tform = randomAffine2d(...
        'XReflection',true,...
        'XTranslation', xTrans, ...
        'YTranslation', yTrans);
    
    % Center the view at the center of image in the output space while
    % allowing translation to move the output image out of view.
    rout = affineOutputView(size(data{i,1}), tform, 'BoundsStyle', 'centerOutput');
    
    % Warp the image and pixel labels using the same transform.
    data{i,1} = imwarp(data{i,1}, tform, 'OutputView', rout);
    data{i,2} = imwarp(data{i,2}, tform, 'OutputView', rout);


end
end

