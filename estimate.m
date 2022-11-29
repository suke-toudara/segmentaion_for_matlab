clear;
%推論結果を表示
estimate_flag=true;
%estimate_flag=false;

%分割処理するか
partition_obj_flag=true ;
%partition_obj_flag=false;

%ポイントクラウドを表示
point_cloud_flag=true ;
%point_cloud_flag=false ;

%%
%モデルの読み込み
data = load('bestmodel3.mat'); 
net = data.net;


% ネットワークのテスト
% テストデータ読み込み
i=3; %i枚目を推論にかける
dataFolder = fullfile(pwd,'data'); 
imgDir = fullfile(dataFolder,'train');
imdsTrain = imageDatastore(imgDir);
%イメージの表示
I = readimage(imdsTrain,i);
figure
imshow(I)

%I=rot90(I);
I=imresize(I ,[960 540]);
    
%推論の実行
C = semanticseg(I, net);

cmap = camvidColorMap;
if (estimate_flag)
    B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
    figure
    imshow(B) 
end

tic
if partition_obj_flag
    %各ラベルを対応するint型の値に変換
    str_result=string(C);
    result=zeros(960, 540,'uint16');
    result(str_result=="back_ground")=0;
    result(str_result=="pillow" | str_result=="boudle")=1;
    result(str_result=="stem")=2;
    
    result_sub1=zeros(960,540, 'uint16');
    result_sub2=zeros(960,540,'uint16');
    result_sub3=zeros(960, 540,'uint16');
    result_sub1(str_result=="back_ground")=0;
    result_sub1(str_result=="stem")=1;
    result_sub2(str_result=="back_ground")=0;
    result_sub2(str_result=="pillow")=1;
    result_sub3(str_result=="back_ground")=0;
    result_sub3(str_result=="boudle")=1;
    
    result_sub1=noize_remove(result_sub1);
    result_sub2=noize_remove(result_sub2);
    result_sub3=noize_remove(result_sub3);
    result_sub=result_sub1+result_sub2+result_sub3;
    %オープン、クロージング作業でノイズ除去
    mask_data=imbinarize(result_sub);  
    se = strel('disk',5);
    close = imclose(mask_data,se);
    Open = imopen(close,se);
    obstacle_map=result.*cast(Open,"uint16");
    obstacle_map=imbinarize(obstacle_map);
    obstacle_map=imresize(obstacle_map ,[1920 1080]);
else
    str_result=string(C);
    result=zeros(960, 540,'uint16');
    result(str_result=="back_ground")=0;
    result(str_result=="pillow" | str_result=="boudle")=1;
    result(str_result=="stem")=2;
    result=noize_remove(result);
    se = strel('disk',5);
    close = imclose(result,se);
    Open = imopen(close,se);
    obstacle_map=Open;
    obstacle_map=imresize(obstacle_map ,[1920 1080]);
end

figure
imshow(obstacle_map)
toc




%
if (point_cloud_flag) 
    rgbd_label = color_image;
    for i = 1:960 
       for j = 1:540
        d = obstacle_map(i,j);
        if (d==1) 
          rgbd_label(i,j,:,:,:) = [243,243,35];
        elseif  (d==2)
          rgbd_label(i,j,:,:,:) = [18,104,21] ;
        else
          rgbd_label(i,j,:,:,:) = [255,255,255] ;
        end
      end
    end
    
    
    %imshow(rgbd_label)
    
    
    %要素を追加する
    %いまz成分しか入っていないのをx,y成分まで足す
    rgbd_image = color_image;
    for i = 1:960
      for j = 1:540
        rgbd_image(i,j,:) = [double(i/15)    double(j/15)    double(depth_image(i,j)/100)];
      end
    end 
   
    %ポイントクラウドの範囲がx,y,zそれぞれ250までと設定されているっぽい
    %ここのデータは読み取り専用で変更出来なかった
    %ポイントクラウドに変換してからなら割とうまくいく
    ptCloud = pointCloud(cast(rgbd_image,'double'),Color=rgbd_label) ;
    %ptCloud = pointCloud(cast(rgbd_image,'double'),Color=color_image) ;
    figure
    pcshow(ptCloud)

end


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
%%
function img = noize_remove(img)
img=imbinarize(img);

CC = bwconncomp(img);
numPixels = cellfun(@numel,CC.PixelIdxList);
    for i = 1:length(numPixels)
        if numPixels(i)<800
            %numPixels(i)=0;
            img(CC.PixelIdxList{i}) = 0;
        end
    end
end

