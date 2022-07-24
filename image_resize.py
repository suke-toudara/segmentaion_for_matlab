from logging import root
from PIL import Image
import glob 
import os
from pathlib import Path
import argparse

"""

matlabの学習用に元画像もネットワークに適したサイズに変更

"""

#ここで出力するイメージのサイズを選択
output_image_size=(960,540)

parser = argparse.ArgumentParser(description='jsonからラベル画像を生成するためのプログラム')
#コマンドライン引数の追加
#-はなくてもいい引数（オプション引数）
parser.add_argument("original_data_dir", help="オリジナル画像があるディレクトリを入力") #jsonがあるディレクトリを入力
parser.add_argument("output_dir", required=True, help="イズ変更した画像を保存するディレクトリを選択") #サイズ変更した画像を保存するディレクトリを選択

#引数を解析する
args = parser.parse_args()
#arg.'ここをadd_argumentの最初の引数を入れる'で持ってきたい値を選択
rootpath = Path(args.original_data_dir)
out_dir_path = Path(args.output_dir)

def make_datapath_list(rootpath):
    data_list=glob.glob(rootpath+'/*.png')
    file_names = []
    for i in range(len(data_list)):
        a,b = os.path.split(data_list[i])
        file_names.append(b)
    return data_list,file_names



path,file_name=make_datapath_list(rootpath)

for i in range(len(path)):
    data=path[i]
    name=file_name[i]
    img = Image.open(data)
    img1=img.resize(output_image_size)
    print(i)
    img1.save(out_dir_path+"/"+name)  # 画像を保存
    #img1.save("./originaldata_for_matlab/"+name)  # 画像を保存


