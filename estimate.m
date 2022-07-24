%%
%推論の設定
data = load('trainedNetwork.mat'); 
net = data.net;

%%
% ネットワークのテスト
%テストデータ読み込み
i=6; %i枚目を推論にかける
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train');
imdsTrain = imageDatastore(imgDir);
%イメージの表示
I = readimage(imdsTrain,i);
I=imresize(I ,[540 960]);
tic;
C = semanticseg(I, net);
toc
cmap = camvidColorMap;
%推論時間は




%ここで障害物を検知したい範囲を決定
%（例）トマトの中心座標が(50,338)だった場合
t = [50  338];
disp(C(t(1)-3:t(1)+3,t(2)-3:t(2)+3)); 
%トマトの中心座標を基にエンドエフェクタが干渉する範囲を捜索


%遅すぎて使えない
%{
d = zeros(540,960);

for i = 1:540  
    for j = 1:960 
        if C(i,j) == "back_ground"
            d(i,j)=0;
        else
            d(i,j)=1;
        end
    end
end
se = offsetstrel('ball',15,15);
d1 = imerode(d,se);
d2 = imdilate(d1,se);

C1 = zeros(540,960);
for i = 1:540  
    for j = 1:960 
        if d2(i,j) == 0
            C1(i,j)="back_ground";
        else
            C1(i,j)=C(i,j);
        end
    end
end
%}

B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
imshow(B)

%imshow(d2), title('D')
%pixelLabelColorbar(cmap, classes);
%expectedResult = readimage(pxdsTest,35);
%actual = uint8(C);
%expected = uint8(expectedResult);
%imshowpair(actual, expected)


%iou = jaccard(C,expectedResult);
%table(classes,iou)




%%
function cmap = camvidColorMap()
% Define the colormap used by CamVid dataset.

cmap = [
    0 128 0   %  "boudle"
    128 0 0       % "stem" 
    128 128 0   % "pillow"
    0 0 0     % "back_ground"
    ];

% Normalize between [0 1].
cmap = cmap ./ 255;
end


%%
function pixelLabelColorbar(cmap, classNames)
% Add a colorbar to the current axis. The colorbar is formatted
% to display the class names with the color.

colormap(gca,cmap)

% Add colorbar to current figure.
c = colorbar('peer', gca);

% Use class names for tick marks.
c.TickLabels = classNames;
numClasses = size(cmap,1);

% Center tick labels.
c.Ticks = 1/(numClasses*2):1/numClasses:1;

% Remove tick mark.
c.TickLength = 0;
end