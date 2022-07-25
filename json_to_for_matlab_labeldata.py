from pathlib import Path
import subprocess
import shutil
import argparse
import tqdm
from PIL import Image
import numpy as np

TEMP_DIR = "temp"

#パーサを作る
parser = argparse.ArgumentParser(description='jsonからラベル画像を生成するためのプログラム')
#コマンドライン引数の追加
#-はなくてもいい引数（オプション引数）
parser.add_argument("json_dir", help="JSON files directory.") #jsonがあるディレクトリを入力
parser.add_argument("-o", required=True, help="Output directory.") #ラベル画像を出力ディレクトリを入力
parser.add_argument("-label_file", required=True, help="Label name file.") #ラベルの一覧を示すtxtファイルのパスを選択

#引数を解析する
args = parser.parse_args()
#arg.'ここをadd_argumentの最初の引数を入れる'で持ってきたい値を選択
json_dir_path = Path(args.json_dir)
out_dir_path = Path(args.o)
label_file_path = Path(args.label_file)

#exisits()はファイルがあるかの確認
#assertは条件式がFalseになるとカンマ以下の値を出力する
assert json_dir_path.exists(), "JSON directory is not exist."
assert out_dir_path.exists(), "Output directory is not exist."
assert label_file_path.exists(), "Label file is not exist."



correct_label_dict = {}
#読み込みモードでラベル画像を読み込み
with open(str(label_file_path), "r") as file:
    #存在するデータの数だけemumerateはリストやタプルなどの要素と同時にインデックス番号を取得
    for i, line in enumerate(file):
        #改行があった場合消す
        correct_label_dict[line.replace("\n", "")] = i + 1

#出力用ディレクトリに一時保存ディレクトリを作成
temp_dir_path = out_dir_path.joinpath(TEMP_DIR)
#一時ディレクトリを作成
if not temp_dir_path.exists():
    temp_dir_path.mkdir()

#jsonファイルのパスを全部取得してくる
for json_file_path in tqdm.tqdm(list(json_dir_path.glob("*.json"))):
    # []内のコマンドが実行される
    #stdoutに標準出力、stderrに標準エラーが出力される。(text=Trueにしておく必要あり)
    #ただ内容をcmdに出力しているだけ
    subprocess.run(["labelme_json_to_dataset", str(json_file_path), "-o", str(temp_dir_path)], stdout=subprocess.PIPE,
                   stderr=subprocess.PIPE, text=True)
    #indexカラーで開く（パレットモード）
    image = Image.open(str(temp_dir_path.joinpath("label.png"))).convert("P")
    #ピクセルごとのRGBを取り出す。
    origin_color_palette = image.getpalette()
    #numpy配列に直す
    image_array = np.array(image)

    
    label_indexes = {}
    #読み込みモードでラベルファイルを開く
    with open(str(temp_dir_path.joinpath("label_names.txt")), "r") as label_file:
        #ラベルファイルからラベルのインデックスとラベル名を取得
        for label_num, label_name in enumerate(label_file):
            #改行があったら消す
            label_name = label_name.replace("\n", "")
            #背景だった場合はそのまま
            if label_name == "_background_":
                continue
            label_indexes[label_name] = (image_array == label_num)

        for label_name, label_index in label_indexes.items():
            #ラベル名に対応した値をimage_array(ラベル配列）に配置していく
            correct_label_num = correct_label_dict[label_name]
            image_array[label_index] = correct_label_num
   
    #ここでPillowに対応した配列に変換し、各ピクセルにRGBの３つ格納していく
    new_image = Image.fromarray(image_array, mode="P")
    new_image.putpalette(origin_color_palette)
    new_image=new_image.convert("RGB")
    new_image=new_image.resize((960,540))
    new_image.save(str(out_dir_path.joinpath(json_file_path.name).with_suffix(".png")))

# temp_dir_path（一時保存用のファイルやサブディレクトリをすべて削除）
if temp_dir_path.exists():
    shutil.rmtree(str(temp_dir_path))

print("Conversion is finished.")
