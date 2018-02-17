from glob import glob
import shutil

egg_info_path = glob('*.egg-info')[0]

try:
    shutil.rmtree(egg_info_path)
    shutil.rmtree('build')
    shutil.rmtree('dist')
    # # FIXME: This could be a problem.
    # shutil.rmtree('notebook_mapper\\__pycache__')

except Exception:
    print('Cleaning failed.')
