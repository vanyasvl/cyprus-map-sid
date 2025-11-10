from pyhgtmap import hgt
import glob
import os

# Путь к HGT файлам (в tmp)
hgt_files = glob.glob("*.hgt")

# Параметры
step = 20
line_cat = [400, 50]  # высоты
no_zero_contour = True

# Папка вывода
output_prefix = "contour"
output_dir = os.getcwd()

# Генерация контуров
hgt.generate_contours_from_files(
    hgt_files,
    output_dir=output_dir,
    step=step,
    line_cat=line_cat,
    no_zero_contour=no_zero_contour
)
